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
                // Column headers
                HStack {
                    Text("App")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Energy / CO\u{2082}")
                        .frame(width: 100, alignment: .trailing)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                Divider().padding(.horizontal, 12)

                ForEach(summaries) { summary in
                    DailyRow(summary: summary)

                    if summary.id != summaries.last?.id {
                        Divider().padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
}

private struct DailyRow: View {
    let summary: AppCarbonSummary
    @State private var isHovered = false

    var body: some View {
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
                Text("\u{2248} \(summary.formattedCO2) CO\u{2082}")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
