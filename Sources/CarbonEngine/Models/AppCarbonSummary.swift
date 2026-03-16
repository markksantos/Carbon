import Foundation

/// Per-app daily energy and carbon totals.
public struct AppCarbonSummary: Sendable, Identifiable {
    public var id: String { bundleId }

    public let appName: String
    public let bundleId: String
    public let wattHours: Double
    public let co2Grams: Double

    public init(appName: String, bundleId: String, wattHours: Double, co2Grams: Double) {
        self.appName = appName
        self.bundleId = bundleId
        self.wattHours = wattHours
        self.co2Grams = co2Grams
    }

    public var formattedWh: String { CarbonCalculator.formatWh(wattHours) }
    public var formattedCO2: String { CarbonCalculator.formatCO2(co2Grams) }
}
