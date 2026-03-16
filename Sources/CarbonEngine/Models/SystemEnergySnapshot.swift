import Foundation

public struct SystemEnergySnapshot: Sendable {
    public let timestamp: Date
    public let appSnapshots: [AppEnergySnapshot]
    public let totalCPUWatts: Double
    public let gpuWatts: Double
    public let displayWatts: Double
    public let totalWatts: Double
    public let chipInfo: ChipInfo

    public init(
        timestamp: Date,
        appSnapshots: [AppEnergySnapshot],
        totalCPUWatts: Double,
        gpuWatts: Double = 0,
        displayWatts: Double,
        totalWatts: Double,
        chipInfo: ChipInfo
    ) {
        self.timestamp = timestamp
        self.appSnapshots = appSnapshots
        self.totalCPUWatts = totalCPUWatts
        self.gpuWatts = gpuWatts
        self.displayWatts = displayWatts
        self.totalWatts = totalWatts
        self.chipInfo = chipInfo
    }
}
