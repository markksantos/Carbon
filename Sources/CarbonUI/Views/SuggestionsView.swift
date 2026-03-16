import SwiftUI
import CarbonEngine

public struct SuggestionsView: View {
    let suggestions: [EnergySuggestion]

    public init(suggestions: [EnergySuggestion]) {
        self.suggestions = suggestions
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tips")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 6)

            ForEach(suggestions.prefix(3)) { suggestion in
                SuggestionCard(suggestion: suggestion)
            }
        }
        .padding(.bottom, 4)
    }
}

private struct SuggestionCard: View {
    let suggestion: EnergySuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(suggestion.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(String(format: "-%.0fW", suggestion.potentialSavingsWatts))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch suggestion.category {
        case .backgroundApp: return "moon.fill"
        case .browser:       return "globe"
        case .gpu:           return "gpu"
        case .display:       return "sun.max.fill"
        }
    }

    private var iconColor: Color {
        switch suggestion.category {
        case .backgroundApp: return .purple
        case .browser:       return .blue
        case .gpu:           return .orange
        case .display:       return .yellow
        }
    }
}
