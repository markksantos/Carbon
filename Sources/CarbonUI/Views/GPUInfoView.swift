import SwiftUI
import CarbonEngine

/// Inline GPU utilization + watts display for the popover.
public struct GPUInfoView: View {
    let utilization: Double
    let watts: Double

    public init(utilization: Double, watts: Double) {
        self.utilization = utilization
        self.watts = watts
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gpu")
                .foregroundStyle(.purple)

            Text("GPU")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: min(utilization / 100.0, 1.0))
                .frame(width: 60)

            Text(String(format: "%.0f%%", utilization))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)

            Text(String(format: "%.1f W", watts))
                .font(.caption.monospacedDigit())
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
