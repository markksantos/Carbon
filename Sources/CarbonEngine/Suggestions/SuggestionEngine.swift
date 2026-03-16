import Foundation

public struct EnergySuggestion: Sendable, Identifiable {
    public let id: String
    public let category: Category
    public let title: String
    public let detail: String
    public let potentialSavingsWatts: Double

    public enum Category: String, Sendable {
        case backgroundApp = "Background App"
        case browser = "Browser"
        case gpu = "GPU"
        case display = "Display"
    }

    public init(id: String, category: Category, title: String, detail: String, potentialSavingsWatts: Double) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
        self.potentialSavingsWatts = potentialSavingsWatts
    }
}

/// Rules-based suggestion engine that evaluates a system snapshot
/// and returns actionable energy-saving tips.
public struct SuggestionEngine: Sendable {
    public init() {}

    public func evaluate(snapshot: SystemEnergySnapshot) -> [EnergySuggestion] {
        var suggestions: [EnergySuggestion] = []

        // Rule 1: Background app consuming >5W
        for app in snapshot.appSnapshots {
            if app.estimatedWatts > 5, app.bundleIdentifier != nil {
                suggestions.append(EnergySuggestion(
                    id: "bg-\(app.name)",
                    category: .backgroundApp,
                    title: "\(app.name) is using \(String(format: "%.1f W", app.estimatedWatts))",
                    detail: "Consider closing it if not in use to save energy.",
                    potentialSavingsWatts: app.estimatedWatts
                ))
            }
        }

        // Rule 2: Tab-heavy browsers (high CPU for browser bundles)
        let browserBundles = Set(["com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
                                   "com.microsoft.edgemac", "com.brave.Browser"])
        for app in snapshot.appSnapshots {
            if let bid = app.bundleIdentifier, browserBundles.contains(bid), app.estimatedWatts > 3 {
                suggestions.append(EnergySuggestion(
                    id: "browser-\(bid)",
                    category: .browser,
                    title: "\(app.name) tabs using \(String(format: "%.1f W", app.estimatedWatts))",
                    detail: "Close unused tabs or use a tab suspender to reduce energy use.",
                    potentialSavingsWatts: app.estimatedWatts * 0.5
                ))
            }
        }

        // Rule 3: High GPU utilization without obvious GPU app
        if snapshot.gpuWatts > 10 {
            let gpuApps = snapshot.appSnapshots.filter { $0.gpuWatts > 1 }
            if gpuApps.isEmpty {
                suggestions.append(EnergySuggestion(
                    id: "gpu-unknown",
                    category: .gpu,
                    title: "GPU using \(String(format: "%.0f W", snapshot.gpuWatts)) with no obvious consumer",
                    detail: "Check for hardware-accelerated background processes.",
                    potentialSavingsWatts: snapshot.gpuWatts * 0.3
                ))
            }
        }

        // Rule 4: Display brightness tip
        if snapshot.displayWatts > 5 {
            suggestions.append(EnergySuggestion(
                id: "display-brightness",
                category: .display,
                title: "Display using \(String(format: "%.1f W", snapshot.displayWatts))",
                detail: "Lowering brightness saves significant energy on Retina displays.",
                potentialSavingsWatts: snapshot.displayWatts * 0.3
            ))
        }

        return suggestions.sorted { $0.potentialSavingsWatts > $1.potentialSavingsWatts }
    }
}
