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
        #expect(info.chipFamily != .unknown)
    }

    @Test("TDP values are reasonable")
    func tdpRange() {
        let info = ChipInfo.detect()
        #expect(info.tdpWatts >= 10 && info.tdpWatts <= 80)
        #expect(info.gpuBaseTDP >= 10 && info.gpuBaseTDP <= 80)
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
