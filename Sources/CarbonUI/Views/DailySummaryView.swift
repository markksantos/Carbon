import SwiftUI
import CarbonEngine

public struct DailySummaryView: View {
    let summaries: [AppCarbonSummary]

    public init(summaries: [AppCarbonSummary]) {
        self.summaries = summaries
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(summaries) { summary in
                    HStack {
                        AppIconView(bundleIdentifier: summary.bundleId)
                            .frame(width: 20, height: 20)

                        Text(summary.appName)
                            .font(.callout)
                            .lineLimit(1)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(summary.formattedWh)
                                .font(.caption.monospacedDigit())
                            Text("≈ \(summary.formattedCO2) CO₂")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    if summary.id != summaries.last?.id {
                        Divider().padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
}
