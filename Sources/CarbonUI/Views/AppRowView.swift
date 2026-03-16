import SwiftUI
import CarbonEngine

public struct AppRowView: View {
    let app: AppEnergySnapshot

    public init(app: AppEnergySnapshot) {
        self.app = app
    }

    public var body: some View {
        HStack(spacing: 8) {
            AppIconView(bundleIdentifier: app.bundleIdentifier)
                .frame(width: 24, height: 24)

            Text(app.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.callout)

            Spacer()

            Text(String(format: "%.0f%%", app.cpuUsagePercent))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)

            if app.gpuWatts > 0.01 {
                Text(String(format: "+%.1fG", app.gpuWatts))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.purple)
                    .frame(width: 38, alignment: .trailing)
            }

            Text(String(format: "%.1f W", app.totalWatts))
                .font(.caption.monospacedDigit())
                .frame(width: 50, alignment: .trailing)

            EnergyBadge(impact: app.energyImpact)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
