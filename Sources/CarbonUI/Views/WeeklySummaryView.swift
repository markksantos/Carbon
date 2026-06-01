import SwiftUI
import Charts
import CarbonEngine

public struct WeeklySummaryView: View {
    let dailyTotals: [DailyTotal]
    let carbonIntensity: Double
    @Bindable var viewModel: CarbonViewModel
    @State private var showingReport = false

    private var totalWh: Double { dailyTotals.reduce(0) { $0 + $1.wattHours } }
    private var totalCO2: Double { dailyTotals.reduce(0) { $0 + $1.co2Grams } }

    public init(dailyTotals: [DailyTotal], carbonIntensity: Double, viewModel: CarbonViewModel) {
        self.dailyTotals = dailyTotals
        self.carbonIntensity = carbonIntensity
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Headline stats
            HStack {
                StatBox(title: "Energy", value: CarbonCalculator.formatWh(totalWh))
                StatBox(title: "CO\u{2082}", value: CarbonCalculator.formatCO2(totalCO2))
            }
            .padding(.horizontal, 12)

            // Bar chart
            EnergyChartView(dailyTotals: dailyTotals)
                .frame(height: 120)
                .padding(.horizontal, 12)

            // View Report button
            Button {
                Task {
                    await viewModel.generateWeeklyReport()
                    showingReport = true
                }
            } label: {
                Text("View Report")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 12)
            .sheet(isPresented: $showingReport) {
                if let report = viewModel.weeklyReport {
                    WeeklyReportView(report: report)
                        .frame(width: 340, height: 420)
                }
            }
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
