import Foundation

/// Describes the Apple Silicon chip powering this machine, including a
/// thermal design power (TDP) estimate used to convert CPU/GPU utilization
/// into watts.
///
/// Chip detection is forward compatible: rather than hardcoding a fixed list
/// of chip families, it parses the generation number (M1, M2, …, M5, …) and
/// the performance tier (base / Pro / Max / Ultra) directly from the CPU brand
/// string. This means a brand-new chip (e.g. "Apple M5 Max") is recognized
/// without a code change, falling back to sensible tier-based TDP values.
public struct ChipInfo: Sendable {
    public let brandString: String
    public let generation: Int
    public let tier: Tier
    public let tdpWatts: Double
    public let cpuCoreCount: Int
    public let gpuBaseTDP: Double

    /// Performance tier within a generation. TDP scales with tier.
    public enum Tier: String, Sendable, CaseIterable {
        case base = ""
        case pro = "Pro"
        case max = "Max"
        case ultra = "Ultra"
    }

    public init(
        brandString: String,
        generation: Int,
        tier: Tier,
        tdpWatts: Double,
        cpuCoreCount: Int,
        gpuBaseTDP: Double
    ) {
        self.brandString = brandString
        self.generation = generation
        self.tier = tier
        self.tdpWatts = tdpWatts
        self.cpuCoreCount = cpuCoreCount
        self.gpuBaseTDP = gpuBaseTDP
    }

    /// Whether the chip generation was successfully identified.
    public var isAppleSilicon: Bool { generation > 0 }

    /// Human-readable chip name, e.g. "M5 Max", "M2", or "Unknown".
    public var displayName: String {
        guard isAppleSilicon else { return "Unknown" }
        let base = "M\(generation)"
        return tier == .base ? base : "\(base) \(tier.rawValue)"
    }

    public static func detect() -> ChipInfo {
        let brand = sysctlString("machdep.cpu.brand_string")
        let coreCount = sysctlInt("hw.ncpu")
        let (generation, tier) = parse(brand)
        return ChipInfo(
            brandString: brand,
            generation: generation,
            tier: tier,
            tdpWatts: tdp(generation: generation, tier: tier),
            cpuCoreCount: max(coreCount, 1),
            gpuBaseTDP: gpuTDP(generation: generation, tier: tier)
        )
    }

    /// Parse a brand string like "Apple M5 Max" into (generation, tier).
    /// Returns (0, .base) when no Apple Silicon generation is found.
    static func parse(_ brand: String) -> (generation: Int, tier: Tier) {
        let lower = brand.lowercased()

        // Find an "m<number>" token (m1, m2, …, m12). Use a regex-free scan so
        // we don't depend on Foundation regex availability semantics.
        var generation = 0
        let scalars = Array(lower.unicodeScalars)
        var i = 0
        while i < scalars.count {
            if scalars[i] == "m" {
                // Token boundary: preceding char must be non-alphanumeric.
                let prevOK = i == 0 || !isAlphaNum(scalars[i - 1])
                var j = i + 1
                var digits = ""
                while j < scalars.count, CharacterSet.decimalDigits.contains(scalars[j]) {
                    digits.unicodeScalars.append(scalars[j])
                    j += 1
                }
                // Next char after digits must be a boundary (not a letter), so
                // we don't match things like "mp3" or "html5".
                let nextOK = j >= scalars.count || !isAlpha(scalars[j])
                if prevOK, nextOK, let value = Int(digits), value > 0 {
                    generation = value
                    break
                }
            }
            i += 1
        }

        let tier: Tier
        if lower.contains("ultra") {
            tier = .ultra
        } else if lower.contains("max") {
            tier = .max
        } else if lower.contains("pro") {
            tier = .pro
        } else {
            tier = .base
        }

        return (generation, tier)
    }

    private static func isAlpha(_ s: Unicode.Scalar) -> Bool {
        (s >= "a" && s <= "z") || (s >= "A" && s <= "Z")
    }

    private static func isAlphaNum(_ s: Unicode.Scalar) -> Bool {
        isAlpha(s) || CharacterSet.decimalDigits.contains(s)
    }

    /// Tier-based CPU TDP estimate (watts). Values approximate the sustained
    /// package power Apple Silicon draws under heavy CPU load and are stable
    /// across generations, so future chips inherit reasonable defaults.
    static func tdp(generation: Int, tier: Tier) -> Double {
        guard generation > 0 else { return 20 } // unknown chip → Pro-ish default
        switch tier {
        case .base:  return 10
        case .pro:   return 20
        case .max:   return 30
        case .ultra: return 60
        }
    }

    /// Tier-based GPU TDP estimate (watts).
    static func gpuTDP(generation: Int, tier: Tier) -> Double {
        guard generation > 0 else { return 20 }
        switch tier {
        case .base:  return 10
        case .pro:   return 20
        case .max:   return 40
        case .ultra: return 80
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
