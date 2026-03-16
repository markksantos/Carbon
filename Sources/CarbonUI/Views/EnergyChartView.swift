import SwiftUI
import Charts
import CarbonEngine

/// Reusable bar chart showing daily kWh for up to 7 days.
public struct EnergyChartView: View {
    let dailyTotals: [DailyTotal]

    public init(dailyTotals: [DailyTotal]) {
        self.dailyTotals = dailyTotals
    }

    public var body: some View {
        Chart(dailyTotals) { total in
            BarMark(
                x: .value("Day", total.date, unit: .day),
                y: .value("Wh", total.wattHours)
            )
            .foregroundStyle(.green.gradient)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let wh = value.as(Double.self) {
                        Text(CarbonCalculator.formatWh(wh))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}
