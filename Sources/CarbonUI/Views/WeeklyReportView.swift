import SwiftUI
import CarbonEngine

public struct WeeklyReportView: View {
    let report: WeeklyReport

    public init(report: WeeklyReport) {
        self.report = report
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Headline
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Report")
                        .font(.headline)
                    if let change = report.changeFromPreviousWeek {
                        Text(changeText(change))
                            .font(.caption)
                            .foregroundStyle(change <= 0 ? .green : .red)
                    }
                }
                Spacer()
            }

            // Stats
            HStack(spacing: 12) {
                StatCard(title: "Energy", value: report.formattedEnergy, icon: "bolt.fill")
                StatCard(title: "CO₂", value: report.formattedCO2, icon: "leaf.fill")
            }

            // Chart
            EnergyChartView(dailyTotals: report.dailyTotals)
                .frame(height: 120)

            // Top consumers
            if !report.topConsumers.isEmpty {
                Text("Top Consumers")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ForEach(report.topConsumers) { app in
                    HStack {
                        Text(app.appName)
                            .font(.caption)
                        Spacer()
                        Text("\(app.formattedWh) | \(app.formattedCO2)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
    }

    private func changeText(_ pct: Double) -> String {
        let arrow = pct <= 0 ? "↓" : "↑"
        return "\(arrow) \(String(format: "%.0f%%", abs(pct))) vs last week"
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
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
