import Foundation

public struct WeeklyReport: Sendable {
    public let totalWh: Double
    public let totalCO2Grams: Double
    public let dailyTotals: [DailyTotal]
    public let topConsumers: [AppCarbonSummary]
    public let changeFromPreviousWeek: Double? // percentage
    public let suggestions: [EnergySuggestion]

    public var formattedEnergy: String { CarbonCalculator.formatWh(totalWh) }
    public var formattedCO2: String { CarbonCalculator.formatCO2(totalCO2Grams) }
}

/// Aggregates a week of data into a comprehensive report.
public struct WeeklyReportGenerator: Sendable {
    public init() {}

    public func generate(
        dailyTotals: [DailyTotal],
        topConsumers: [AppCarbonSummary],
        previousWeekWh: Double?,
        suggestions: [EnergySuggestion]
    ) -> WeeklyReport {
        let totalWh = dailyTotals.reduce(0) { $0 + $1.wattHours }
        let totalCO2 = dailyTotals.reduce(0) { $0 + $1.co2Grams }

        let change: Double? = previousWeekWh.map { prev in
            guard prev > 0 else { return 0 }
            return ((totalWh - prev) / prev) * 100
        }

        return WeeklyReport(
            totalWh: totalWh,
            totalCO2Grams: totalCO2,
            dailyTotals: dailyTotals,
            topConsumers: Array(topConsumers.prefix(5)),
            changeFromPreviousWeek: change,
            suggestions: suggestions
        )
    }
}
