import Foundation
import IOKit

/// Reads system-wide GPU utilization from IOAccelerator and estimates GPU watts.
/// Note: GPU attribution to individual apps is heuristic — IOAccelerator only
/// exposes system-wide utilization, not per-process.
public actor GPUTracker {
    private let chipInfo: ChipInfo
    private var lastUtilization: Double = 0

    public init(chipInfo: ChipInfo) {
        self.chipInfo = chipInfo
    }

    /// Returns estimated total GPU watts based on current utilization.
    public func sample() -> Double {
        let utilization = readGPUUtilization()
        lastUtilization = utilization
        return utilization / 100.0 * chipInfo.gpuBaseTDP
    }

    /// Last-sampled GPU utilization percentage (0-100).
    public func currentUtilization() -> Double {
        lastUtilization
    }

    private func readGPUUtilization() -> Double {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess else {
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }

            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                  let dict = props?.takeRetainedValue() as? [String: Any]
            else {
                service = IOIteratorNext(iterator)
                continue
            }

            // Look for PerformanceStatistics → Device Utilization %
            if let perfStats = dict["PerformanceStatistics"] as? [String: Any],
               let utilization = perfStats["Device Utilization %"] as? NSNumber {
                return utilization.doubleValue
            }

            service = IOIteratorNext(iterator)
        }
        return 0
    }
}
