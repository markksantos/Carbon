import SwiftUI
import CarbonEngine

@Observable
@MainActor
public final class CarbonViewModel {
    public var systemSnapshot: SystemEnergySnapshot?
    public var totalWatts: Double = 0
    public var chipInfo: ChipInfo
    public var lastUpdated: Date?

    // Phase 2 properties
    public var selectedTab: Tab = .live
    public var dailySummaries: [AppCarbonSummary] = []
    public var weeklySummaries: [DailyTotal] = []
    public var regionCode: String
    public var carbonIntensity: Double

    // Phase 3 properties
    public var suggestions: [EnergySuggestion] = []
    public var gpuUtilization: Double = 0
    public var weeklyReport: WeeklyReport?

    private let tracker: ProcessEnergyTracker
    private let resolver: RunningAppResolver
    private let systemInfo: SystemInfoProvider
    private var store: EnergyStore?
    private var gpuTracker: GPUTracker?
    private var gpuAttributor: GPUProcessAttributor?
    private var suggestionEngine: SuggestionEngine?
    private var isRunning = false
    private var lastFlush: Date = .now
    private var previousTotalWatts: Double = 0

    public enum Tab: String, CaseIterable {
        case live = "Live"
        case today = "Today"
        case week = "Week"
    }

    public var databaseURL: URL? {
        EnergyStore.databaseDirectoryURL
    }

    public init() {
        let chip = ChipInfo.detect()
        self.chipInfo = chip
        self.tracker = ProcessEnergyTracker(chipInfo: chip)
        self.resolver = RunningAppResolver()
        self.systemInfo = SystemInfoProvider()
        self.regionCode = CarbonIntensityTable.detectRegion()
        self.carbonIntensity = CarbonIntensityTable.intensity(for: CarbonIntensityTable.detectRegion())

        // Initialize Phase 2 storage
        Task { @MainActor in
            do {
                let store = try await EnergyStore()
                self.store = store
            } catch {
                print("Carbon: failed to initialize storage: \(error)")
            }
        }

        // Initialize Phase 3 GPU tracking + suggestions
        self.gpuTracker = GPUTracker(chipInfo: chip)
        self.gpuAttributor = GPUProcessAttributor(chipInfo: chip)
        self.suggestionEngine = SuggestionEngine()

        start()
    }

    public func start() {
        isRunning = true
        Task { @MainActor in
            await update()
            while isRunning {
                try? await Task.sleep(for: .seconds(5))
                guard isRunning else { break }
                await update()
            }
        }
    }

    public func stop() {
        isRunning = false
    }

    public func pause() {
        isRunning = false
    }

    public func resume() {
        guard !isRunning else { return }
        start()
    }

    public func selectTab(_ tab: Tab) {
        selectedTab = tab
        if tab == .today {
            Task { await loadDailySummaries() }
        } else if tab == .week {
            Task { await loadWeeklySummaries() }
        }
    }

    public func updateRegion(_ code: String) {
        regionCode = code
        carbonIntensity = CarbonIntensityTable.intensity(for: code)
    }

    public func clearAllData() async {
        guard let store else { return }
        do {
            try await store.deleteAllSamples()
            dailySummaries = []
            weeklySummaries = []
            weeklyReport = nil
        } catch {
            print("Carbon: failed to clear data: \(error)")
        }
    }

    public func generateWeeklyReport() async {
        guard let store else { return }
        let totals = await store.weeklyTotals(carbonIntensity: carbonIntensity)
        let consumers = await store.dailySummaries(for: .now, carbonIntensity: carbonIntensity)
        let previousWeekWh = await store.previousWeekTotalWh()
        let generator = WeeklyReportGenerator()
        weeklyReport = generator.generate(
            dailyTotals: totals,
            topConsumers: consumers,
            previousWeekWh: previousWeekWh,
            suggestions: suggestions
        )
    }

    // MARK: - Private

    private func update() async {
        let apps = resolver.snapshot()
        var appSnapshots = await tracker.sample(runningApps: apps)

        // Phase 3: GPU tracking
        if let gpuTracker, let gpuAttributor {
            let gpuTotal = await gpuTracker.sample()
            gpuUtilization = await gpuTracker.currentUtilization()
            let attributed = await gpuAttributor.attribute(
                totalGPUWatts: gpuTotal,
                apps: appSnapshots,
                frontmostPID: NSWorkspace.shared.frontmostApplication?.processIdentifier
            )
            appSnapshots = attributed
        }

        let displayWatts = systemInfo.displayWatts()
        let totalCPU = appSnapshots.reduce(0) { $0 + $1.estimatedWatts }
        let totalGPU = appSnapshots.reduce(0) { $0 + $1.gpuWatts }
        let total = totalCPU + totalGPU + displayWatts

        // Only update displayed wattage if change > 0.5W (prevents flicker)
        if abs(total - previousTotalWatts) > 0.5 || systemSnapshot == nil {
            self.totalWatts = total
            previousTotalWatts = total
        }

        let snapshot = SystemEnergySnapshot(
            timestamp: .now,
            appSnapshots: appSnapshots,
            totalCPUWatts: totalCPU,
            gpuWatts: totalGPU,
            displayWatts: displayWatts,
            totalWatts: total,
            chipInfo: chipInfo
        )
        self.systemSnapshot = snapshot
        self.lastUpdated = .now

        // Phase 2: flush to storage every 5 minutes (batched)
        if let store, Date.now.timeIntervalSince(lastFlush) >= 300 {
            let batch = appSnapshots.map { app in
                (appName: app.name,
                 bundleId: app.bundleIdentifier ?? app.name,
                 cpuWatts: app.estimatedWatts,
                 gpuWatts: app.gpuWatts,
                 durationSeconds: 5.0,
                 regionCode: regionCode)
            }
            do {
                try await store.recordBatch(batch)
            } catch {
                print("Carbon: failed to flush batch: \(error)")
            }
            lastFlush = .now
        }

        // Phase 3: suggestions
        if let suggestionEngine {
            suggestions = suggestionEngine.evaluate(snapshot: snapshot)
        }
    }

    private func loadDailySummaries() async {
        guard let store else { return }
        dailySummaries = await store.dailySummaries(
            for: .now,
            carbonIntensity: carbonIntensity
        )
    }

    private func loadWeeklySummaries() async {
        guard let store else { return }
        weeklySummaries = await store.weeklyTotals(carbonIntensity: carbonIntensity)
    }
}
