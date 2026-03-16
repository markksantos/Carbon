import Foundation

/// Static table of grid carbon intensity by region code (gCO2/kWh).
/// Values are approximate national averages.
public enum CarbonIntensityTable: Sendable {
    /// gCO2 emitted per kWh of electricity consumed, keyed by ISO country/region code.
    public static let table: [String: Double] = [
        // Americas
        "US": 370, "CA": 120, "BR": 75, "MX": 420, "AR": 310, "CL": 330, "CO": 150,
        // Europe
        "GB": 230, "DE": 350, "FR": 55, "ES": 170, "IT": 310, "NL": 380, "BE": 160,
        "SE": 15, "NO": 20, "FI": 80, "DK": 140, "AT": 90, "CH": 25, "PT": 200,
        "PL": 650, "CZ": 430, "IE": 300, "GR": 450, "RO": 280, "HU": 220,
        // Asia-Pacific
        "CN": 550, "IN": 700, "JP": 450, "KR": 420, "AU": 600, "NZ": 90,
        "SG": 370, "TW": 500, "TH": 430, "ID": 650, "PH": 500, "VN": 400,
        // Middle East & Africa
        "AE": 410, "SA": 550, "IL": 440, "ZA": 850, "EG": 450, "NG": 400,
        "KE": 60, "MA": 620,
    ]

    /// Auto-detect region from system locale.
    public static func detectRegion() -> String {
        if let region = Locale.current.region?.identifier {
            return region
        }
        return "US"
    }

    /// Look up intensity for a given region code, falling back to world average.
    public static func intensity(for regionCode: String) -> Double {
        table[regionCode] ?? 440 // world average fallback
    }
}
