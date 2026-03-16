import Foundation

public struct ChipInfo: Sendable {
    public let brandString: String
    public let chipFamily: ChipFamily
    public let tdpWatts: Double
    public let cpuCoreCount: Int
    public let gpuBaseTDP: Double

    public enum ChipFamily: String, Sendable {
        case m1 = "M1"
        case m1Pro = "M1 Pro"
        case m1Max = "M1 Max"
        case m1Ultra = "M1 Ultra"
        case m2 = "M2"
        case m2Pro = "M2 Pro"
        case m2Max = "M2 Max"
        case m2Ultra = "M2 Ultra"
        case m3 = "M3"
        case m3Pro = "M3 Pro"
        case m3Max = "M3 Max"
        case m3Ultra = "M3 Ultra"
        case m4 = "M4"
        case m4Pro = "M4 Pro"
        case m4Max = "M4 Max"
        case m4Ultra = "M4 Ultra"
        case unknown = "Unknown"
    }

    public static func detect() -> ChipInfo {
        let brand = sysctlString("machdep.cpu.brand_string")
        let coreCount = sysctlInt("hw.ncpu")
        let family = parseFamily(brand)
        return ChipInfo(
            brandString: brand,
            chipFamily: family,
            tdpWatts: tdpForFamily(family),
            cpuCoreCount: coreCount,
            gpuBaseTDP: gpuTDPForFamily(family)
        )
    }

    private static func parseFamily(_ brand: String) -> ChipFamily {
        let s = brand.lowercased()
        // Check generations from newest to oldest; within each, most specific variant first
        let generations: [(String, [(String, ChipFamily)])] = [
            ("m4", [("ultra", .m4Ultra), ("max", .m4Max), ("pro", .m4Pro), ("", .m4)]),
            ("m3", [("ultra", .m3Ultra), ("max", .m3Max), ("pro", .m3Pro), ("", .m3)]),
            ("m2", [("ultra", .m2Ultra), ("max", .m2Max), ("pro", .m2Pro), ("", .m2)]),
            ("m1", [("ultra", .m1Ultra), ("max", .m1Max), ("pro", .m1Pro), ("", .m1)]),
        ]
        for (gen, variants) in generations {
            guard s.contains(gen) else { continue }
            for (suffix, family) in variants {
                if suffix.isEmpty || s.contains(suffix) {
                    return family
                }
            }
        }
        return .unknown
    }

    private static func tdpForFamily(_ family: ChipFamily) -> Double {
        switch family {
        case .m1, .m2, .m3, .m4:                     return 10
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro:          return 20
        case .m1Max, .m2Max, .m3Max, .m4Max:          return 30
        case .m1Ultra, .m2Ultra, .m3Ultra, .m4Ultra:  return 60
        case .unknown:                                return 20
        }
    }

    private static func gpuTDPForFamily(_ family: ChipFamily) -> Double {
        switch family {
        case .m1, .m2, .m3, .m4:                     return 10
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro:          return 20
        case .m1Max, .m2Max, .m3Max, .m4Max:          return 40
        case .m1Ultra, .m2Ultra, .m3Ultra, .m4Ultra:  return 80
        case .unknown:                                return 20
        }
    }

    private static func sysctlString(_ name: String) -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return "Unknown" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        if let idx = buffer.firstIndex(of: 0) { buffer = Array(buffer[..<idx]) }
        return String(decoding: buffer.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private static func sysctlInt(_ name: String) -> Int {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname(name, &value, &size, nil, 0)
        return Int(value)
    }
}
