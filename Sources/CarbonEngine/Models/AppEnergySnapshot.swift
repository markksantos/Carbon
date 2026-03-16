import Foundation

public struct AppEnergySnapshot: Sendable, Identifiable {
    public let id: Int32
    public let name: String
    public let bundleIdentifier: String?
    public let cpuUsagePercent: Double
    public let estimatedWatts: Double
    public var gpuWatts: Double
    public let energyImpact: EnergyImpact

    public enum EnergyImpact: String, Sendable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"

        public static func from(watts: Double) -> EnergyImpact {
            switch watts {
            case ..<1:   return .low
            case 1..<3:  return .medium
            case 3..<10: return .high
            default:     return .veryHigh
            }
        }
    }

    public init(
        id: Int32,
        name: String,
        bundleIdentifier: String?,
        cpuUsagePercent: Double,
        estimatedWatts: Double,
        gpuWatts: Double = 0,
        energyImpact: EnergyImpact
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.cpuUsagePercent = cpuUsagePercent
        self.estimatedWatts = estimatedWatts
        self.gpuWatts = gpuWatts
        self.energyImpact = energyImpact
    }

    /// Total watts including CPU + GPU
    public var totalWatts: Double { estimatedWatts + gpuWatts }
}
