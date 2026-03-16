import Darwin
import Foundation

/// Core actor that samples per-process CPU time every tick, computes
/// delta CPU usage, and converts to estimated watts via chip TDP.
public actor ProcessEnergyTracker {
    private let chipInfo: ChipInfo
    private let enumerator: ProcessEnumerator
    private let timeConverter: MachTimeConverter

    private var previousSamples: [Int32: PreviousSample] = [:]
    private var previousTimestamp: UInt64 = 0

    private struct PreviousSample {
        let totalCPUTicks: UInt64
        let name: String
        let lastSeen: UInt64
    }

    public init(chipInfo: ChipInfo) {
        self.chipInfo = chipInfo
        self.enumerator = ProcessEnumerator()
        self.timeConverter = MachTimeConverter()
    }

    /// Sample all processes, compute delta CPU since last call,
    /// and return per-app energy snapshots sorted by watts descending.
    public func sample(runningApps: [Int32: RunningApp]) -> [AppEnergySnapshot] {
        let now = mach_absolute_time()
        let processes = enumerator.listAll()

        // First sample: record baseline, return empty
        guard previousTimestamp > 0 else {
            recordBaseline(processes, now: now)
            return []
        }

        let deltaTime = timeConverter.seconds(fromTicks: now - previousTimestamp)
        guard deltaTime > 0 else { return [] }

        var seenPIDs = Set<Int32>()
        var bundleAccum: [String: BundleAccumulator] = [:]
        var standaloneSnapshots: [AppEnergySnapshot] = []

        for proc in processes {
            seenPIDs.insert(proc.pid)
            let totalTicks = proc.totalUserTicks + proc.totalSystemTicks
            let cpuPercent = computeCPUPercent(pid: proc.pid, totalTicks: totalTicks, deltaTime: deltaTime)

            previousSamples[proc.pid] = PreviousSample(
                totalCPUTicks: totalTicks, name: proc.name, lastSeen: now
            )

            if let app = runningApps[proc.pid], let bundleId = app.bundleIdentifier {
                let name = app.localizedName ?? proc.name
                bundleAccum[bundleId, default: BundleAccumulator(name: name, bundleId: bundleId)]
                    .add(cpuPercent: cpuPercent, pid: proc.pid)
            } else {
                let watts = cpuPercentToWatts(cpuPercent)
                guard watts >= 0.01 else { continue }
                standaloneSnapshots.append(AppEnergySnapshot(
                    id: proc.pid,
                    name: proc.name,
                    bundleIdentifier: nil,
                    cpuUsagePercent: cpuPercent,
                    estimatedWatts: watts,
                    energyImpact: .from(watts: watts)
                ))
            }
        }

        // Build coalesced bundle snapshots
        let bundleSnapshots: [AppEnergySnapshot] = bundleAccum.values.compactMap { acc in
            let watts = cpuPercentToWatts(acc.cpuPercent)
            guard watts >= 0.01 else { return nil }
            return AppEnergySnapshot(
                id: acc.pids[0],
                name: acc.name,
                bundleIdentifier: acc.bundleId,
                cpuUsagePercent: acc.cpuPercent,
                estimatedWatts: watts,
                energyImpact: .from(watts: watts)
            )
        }

        // Prune dead PIDs (not seen for 30 seconds)
        previousSamples = previousSamples.filter { pid, sample in
            seenPIDs.contains(pid) || timeConverter.seconds(fromTicks: now - sample.lastSeen) < 30
        }
        previousTimestamp = now

        return (bundleSnapshots + standaloneSnapshots).sorted { $0.estimatedWatts > $1.estimatedWatts }
    }

    // MARK: - Private

    private func recordBaseline(_ processes: [ProcessSnapshot], now: UInt64) {
        for proc in processes {
            previousSamples[proc.pid] = PreviousSample(
                totalCPUTicks: proc.totalUserTicks + proc.totalSystemTicks,
                name: proc.name,
                lastSeen: now
            )
        }
        previousTimestamp = now
    }

    private func computeCPUPercent(pid: Int32, totalTicks: UInt64, deltaTime: Double) -> Double {
        guard let prev = previousSamples[pid] else { return 0 }
        let deltaTicks = totalTicks > prev.totalCPUTicks ? totalTicks - prev.totalCPUTicks : 0
        let deltaCPUSeconds = timeConverter.seconds(fromTicks: deltaTicks)
        return (deltaCPUSeconds / deltaTime) * 100.0
    }

    private func cpuPercentToWatts(_ cpuPercent: Double) -> Double {
        let totalCapacity = Double(chipInfo.cpuCoreCount) * 100.0
        return (cpuPercent / totalCapacity) * chipInfo.tdpWatts
    }
}

// MARK: - Bundle Accumulator

private struct BundleAccumulator {
    let name: String
    let bundleId: String
    var cpuPercent: Double = 0
    var pids: [Int32] = []

    mutating func add(cpuPercent: Double, pid: Int32) {
        self.cpuPercent += cpuPercent
        pids.append(pid)
    }
}
