import SwiftUI
import CarbonEngine

public struct EnergyBadge: View {
    let impact: AppEnergySnapshot.EnergyImpact

    public init(impact: AppEnergySnapshot.EnergyImpact) {
        self.impact = impact
    }

    public var body: some View {
        Label(impact.rawValue, systemImage: symbolName)
            .font(.caption2)
            .fontWeight(.medium)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("\(impact.rawValue) energy impact")
    }

    private var symbolName: String {
        switch impact {
        case .low:      return "circle.fill"
        case .medium:   return "triangle.fill"
        case .high:     return "diamond.fill"
        case .veryHigh: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch impact {
        case .low:      return .green
        case .medium:   return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        }
    }
}
