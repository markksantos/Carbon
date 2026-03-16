import SwiftUI
import CarbonEngine

public struct EnergyBadge: View {
    let impact: AppEnergySnapshot.EnergyImpact

    public init(impact: AppEnergySnapshot.EnergyImpact) {
        self.impact = impact
    }

    public var body: some View {
        Text(impact.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
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
