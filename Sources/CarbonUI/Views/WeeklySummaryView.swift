import SwiftUI
import Charts
import CarbonEngine

public struct WeeklySummaryView: View {
    let dailyTotals: [DailyTotal]
    let carbonIntensity: Double

    public init(dailyTotals: [DailyTotal], carbonIntensity: Double) {
        self.dailyTotals = dailyTotals
        self.carbonIntensity = carbonIntensity
    }

    private var totalWh: Double { dailyTotals.reduce(0) { $0 + $1.wattHours } }
    private var totalCO2: Double { dailyTotals.reduce(0) { $0 + $1.co2Grams } }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Headline stats
            HStack {
                StatBox(title: "Energy", value: CarbonCalculator.formatWh(totalWh))
                StatBox(title: "CO₂", value: CarbonCalculator.formatCO2(totalCO2))
            }
            .padding(.horizontal, 12)

            // Bar chart
            EnergyChartView(dailyTotals: dailyTotals)
                .frame(height: 120)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
}

private struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospacedDigit())
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
