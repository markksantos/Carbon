import Darwin

public struct MachTimeConverter: Sendable {
    private let numer: UInt64
    private let denom: UInt64

    public init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        numer = UInt64(info.numer)
        denom = UInt64(info.denom)
    }

    /// Convert Mach absolute time ticks to seconds.
    public func seconds(fromTicks ticks: UInt64) -> Double {
        let nanos = (ticks &* numer) / denom
        return Double(nanos) / 1_000_000_000
    }
}
