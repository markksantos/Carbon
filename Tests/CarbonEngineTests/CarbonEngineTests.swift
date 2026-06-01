import Testing
import Darwin
@testable import CarbonEngine

@Suite("ChipInfo")
struct ChipInfoTests {
    @Test("Detects chip on this machine")
    func detectChip() {
        let info = ChipInfo.detect()
        #expect(!info.brandString.isEmpty)
        #expect(info.cpuCoreCount > 0)
        #expect(info.tdpWatts > 0)
        // On Apple Silicon the generation should be detected; on Intel/CI
        // runners it may not be, so only assert detection when running on
        // a recognized Apple chip.
        if info.brandString.lowercased().contains("apple") {
            #expect(info.isAppleSilicon)
            #expect(info.displayName != "Unknown")
        }
    }

    @Test("TDP values are reasonable")
    func tdpRange() {
        let info = ChipInfo.detect()
        #expect(info.tdpWatts >= 10 && info.tdpWatts <= 80)
        #expect(info.gpuBaseTDP >= 10 && info.gpuBaseTDP <= 80)
    }

    @Test("Forward-compatible chip parsing")
    func parsing() {
        #expect(ChipInfo.parse("Apple M1").generation == 1)
        #expect(ChipInfo.parse("Apple M1").tier == .base)
        #expect(ChipInfo.parse("Apple M2 Pro").generation == 2)
        #expect(ChipInfo.parse("Apple M2 Pro").tier == .pro)
        #expect(ChipInfo.parse("Apple M3 Max").tier == .max)
        #expect(ChipInfo.parse("Apple M2 Ultra").tier == .ultra)
        // Future chip recognized without a code change
        #expect(ChipInfo.parse("Apple M5 Max").generation == 5)
        #expect(ChipInfo.parse("Apple M5 Max").tier == .max)
        #expect(ChipInfo.parse("Apple M12").generation == 12)
        // Non-Apple-Silicon brand → unknown
        #expect(ChipInfo.parse("Intel Core i9").generation == 0)
    }

    @Test("Display name formatting")
    func displayName() {
        let m5max = ChipInfo(
            brandString: "Apple M5 Max", generation: 5, tier: .max,
            tdpWatts: 30, cpuCoreCount: 18, gpuBaseTDP: 40
        )
        #expect(m5max.displayName == "M5 Max")
        let m1 = ChipInfo(
            brandString: "Apple M1", generation: 1, tier: .base,
            tdpWatts: 10, cpuCoreCount: 8, gpuBaseTDP: 10
        )
        #expect(m1.displayName == "M1")
    }
}

@Suite("MachTimeConverter")
struct MachTimeConverterTests {
    @Test("Converts ticks to positive seconds")
    func convertTicks() {
        let converter = MachTimeConverter()
        let start = mach_absolute_time()
        // Busy-wait a tiny bit
        var x = 0
        for i in 0..<1_000_000 { x &+= i }
        _ = x
        let end = mach_absolute_time()
        let seconds = converter.seconds(fromTicks: end - start)
        #expect(seconds > 0)
        #expect(seconds < 10) // shouldn't take 10s for a million iterations
    }
}

@Suite("CarbonCalculator")
struct CarbonCalculatorTests {
    @Test("kWh conversion")
    func kwhConversion() {
        #expect(CarbonCalculator.kWh(wattHours: 1000) == 1.0)
        #expect(CarbonCalculator.kWh(wattHours: 500) == 0.5)
    }

    @Test("CO2 calculation: 5W for 30 min at US intensity")
    func co2Calculation() {
        // 5W × 0.5h = 2.5 Wh = 0.0025 kWh
        // 0.0025 kWh × 370 gCO2/kWh = 0.925 g
        let co2 = CarbonCalculator.co2Grams(watts: 5, seconds: 1800, intensity: 370)
        #expect(abs(co2 - 0.925) < 0.01)
    }

    @Test("CO2 France vs US")
    func regionComparison() {
        let usCO2 = CarbonCalculator.co2Grams(wattHours: 100, intensity: 370)
        let frCO2 = CarbonCalculator.co2Grams(wattHours: 100, intensity: 55)
        #expect(usCO2 > frCO2)
        #expect(frCO2 < usCO2 / 5) // France should be much lower
    }

    @Test("Formatting helpers")
    func formatting() {
        #expect(CarbonCalculator.formatWh(0.5) == "500.0 mWh")
        #expect(CarbonCalculator.formatWh(50) == "50.0 Wh")
        #expect(CarbonCalculator.formatWh(1500) == "1.50 kWh")
        #expect(CarbonCalculator.formatCO2(0.5) == "500.0 mg")
        #expect(CarbonCalculator.formatCO2(50) == "50.0 g")
        #expect(CarbonCalculator.formatCO2(1500) == "1.50 kg")
    }
}

@Suite("CarbonIntensityTable")
struct CarbonIntensityTableTests {
    @Test("Known regions have values")
    func knownRegions() {
        #expect(CarbonIntensityTable.intensity(for: "US") == 370)
        #expect(CarbonIntensityTable.intensity(for: "FR") == 55)
        #expect(CarbonIntensityTable.intensity(for: "DE") == 350)
    }

    @Test("Unknown region falls back to world average")
    func fallback() {
        #expect(CarbonIntensityTable.intensity(for: "XX") == 440)
    }

    @Test("detectRegion returns non-empty string")
    func detectRegion() {
        let region = CarbonIntensityTable.detectRegion()
        #expect(!region.isEmpty)
    }
}

@Suite("ProcessEnumerator")
struct ProcessEnumeratorTests {
    @Test("Lists at least one process")
    func listProcesses() {
        let enumerator = ProcessEnumerator()
        let processes = enumerator.listAll()
        #expect(processes.count > 10) // macOS always has many processes
    }
}

@Suite("WeeklyReportGenerator")
struct WeeklyReportGeneratorTests {
    private func totals() -> [DailyTotal] {
        [
            DailyTotal(date: .now, wattHours: 100, co2Grams: 37),
            DailyTotal(date: .now.addingTimeInterval(-86400), wattHours: 50, co2Grams: 18.5),
        ]
    }

    @Test("Sums daily totals into report")
    func sumsTotals() {
        let report = WeeklyReportGenerator().generate(
            dailyTotals: totals(), topConsumers: [], previousWeekWh: nil, suggestions: []
        )
        #expect(report.totalWh == 150)
        #expect(abs(report.totalCO2Grams - 55.5) < 0.01)
        #expect(report.changeFromPreviousWeek == nil)
    }

    @Test("Computes week-over-week increase")
    func computesIncrease() {
        // This week 150 Wh, last week 100 Wh → +50%
        let report = WeeklyReportGenerator().generate(
            dailyTotals: totals(), topConsumers: [], previousWeekWh: 100, suggestions: []
        )
        #expect(report.changeFromPreviousWeek != nil)
        #expect(abs((report.changeFromPreviousWeek ?? 0) - 50) < 0.01)
    }

    @Test("Computes week-over-week decrease")
    func computesDecrease() {
        // This week 150 Wh, last week 300 Wh → -50%
        let report = WeeklyReportGenerator().generate(
            dailyTotals: totals(), topConsumers: [], previousWeekWh: 300, suggestions: []
        )
        #expect(abs((report.changeFromPreviousWeek ?? 0) + 50) < 0.01)
    }

    @Test("Limits top consumers to 5")
    func limitsConsumers() {
        let consumers = (0..<10).map {
            AppCarbonSummary(appName: "App\($0)", bundleId: "com.test.\($0)", wattHours: 10, co2Grams: 3)
        }
        let report = WeeklyReportGenerator().generate(
            dailyTotals: totals(), topConsumers: consumers, previousWeekWh: nil, suggestions: []
        )
        #expect(report.topConsumers.count == 5)
    }
}

@Suite("SuggestionEngine")
struct SuggestionEngineTests {
    @Test("High-watt app triggers suggestion")
    func backgroundAppSuggestion() {
        let chip = ChipInfo.detect()
        let snapshot = SystemEnergySnapshot(
            timestamp: .now,
            appSnapshots: [
                AppEnergySnapshot(
                    id: 1, name: "TestApp", bundleIdentifier: "com.test.app",
                    cpuUsagePercent: 50, estimatedWatts: 8, energyImpact: .high
                )
            ],
            totalCPUWatts: 8, displayWatts: 3, totalWatts: 11, chipInfo: chip
        )
        let engine = SuggestionEngine()
        let suggestions = engine.evaluate(snapshot: snapshot)
        #expect(!suggestions.isEmpty)
        #expect(suggestions.first?.category == .backgroundApp)
    }
}
