import Foundation
import IOKit
import IOKit.graphics

public struct SystemInfoProvider: Sendable {
    /// Panel max watts: ~7W for 14", ~10W for 16" MacBook Pro
    private let panelMaxWatts: Double

    public init(panelMaxWatts: Double = 7.0) {
        self.panelMaxWatts = panelMaxWatts
    }

    /// Estimate display power: brightness × panel max watts.
    public func displayWatts() -> Double {
        getDisplayBrightness() * panelMaxWatts
    }

    private func getDisplayBrightness() -> Double {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )
        guard result == kIOReturnSuccess else { return 0.5 }
        defer { IOObjectRelease(iterator) }

        var brightness: Float = 0.5
        var service = IOIteratorNext(iterator)
        while service != 0 {
            var value: Float = 0
            let ret = IODisplayGetFloatParameter(
                service, 0,
                kIODisplayBrightnessKey as CFString,
                &value
            )
            if ret == kIOReturnSuccess {
                brightness = value
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return Double(brightness)
    }
}
