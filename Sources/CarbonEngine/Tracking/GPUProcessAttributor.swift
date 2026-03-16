import Foundation

/// Heuristic: attributes system-wide GPU watts to individual apps proportionally.
///
/// Since macOS doesn't expose per-process GPU usage, we estimate:
/// - Apps known to use GPU (browsers, creative apps) get proportional share based on CPU activity
/// - Frontmost app gets a bonus weight (1.5x)
/// - Apps with zero CPU usage get no GPU attribution
public actor GPUProcessAttributor {
    private let chipInfo: ChipInfo

    /// Bundle IDs of apps known to commonly use the GPU.
    private let gpuHeavyBundles: Set<String> = [
        "com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
        "com.microsoft.edgemac", "com.brave.Browser",
        "com.adobe.Photoshop", "com.adobe.Illustrator", "com.adobe.Premiere",
        "com.adobe.AfterEffects", "com.apple.FinalCut", "com.apple.iMovieApp",
        "com.apple.Logic10", "com.figma.Desktop", "com.sketchapp.sketch",
        "com.electron.repl", "com.unity3d.UnityEditor",
        "com.blender.blender", "tv.plex.desktop",
    ]

    public init(chipInfo: ChipInfo) {
        self.chipInfo = chipInfo
    }

    /// Attribute total GPU watts across apps and return updated snapshots.
    public func attribute(
        totalGPUWatts: Double,
        apps: [AppEnergySnapshot],
        frontmostPID: Int32?
    ) -> [AppEnergySnapshot] {
        guard totalGPUWatts > 0.1 else { return apps }

        // Compute weighted scores for GPU-eligible apps
        var weights: [(index: Int, weight: Double)] = []
        var totalWeight: Double = 0

        for (i, app) in apps.enumerated() {
            guard app.cpuUsagePercent > 0.1 else { continue }

            let isGPUHeavy = app.bundleIdentifier.map { gpuHeavyBundles.contains($0) } ?? false
            guard isGPUHeavy else { continue }

            var weight = app.cpuUsagePercent
            if app.id == frontmostPID {
                weight *= 1.5
            }
            weights.append((i, weight))
            totalWeight += weight
        }

        guard totalWeight > 0 else { return apps }

        var result = apps
        for (index, weight) in weights {
            let share = (weight / totalWeight) * totalGPUWatts
            result[index].gpuWatts = share
        }
        return result
    }
}
