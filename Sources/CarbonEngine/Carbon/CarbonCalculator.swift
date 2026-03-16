import Foundation

/// Pure-function carbon footprint calculations.
public enum CarbonCalculator {
    /// Convert watt-hours to kilowatt-hours.
    public static func kWh(wattHours: Double) -> Double {
        wattHours / 1000.0
    }

    /// Grams of CO2 emitted for given watt-hours at given grid intensity (gCO2/kWh).
    public static func co2Grams(wattHours: Double, intensity: Double) -> Double {
        kWh(wattHours: wattHours) * intensity
    }

    /// Grams of CO2 for watts consumed over a duration in seconds.
    public static func co2Grams(watts: Double, seconds: Double, intensity: Double) -> Double {
        let hours = seconds / 3600.0
        let wh = watts * hours
        return co2Grams(wattHours: wh, intensity: intensity)
    }

    // MARK: - Formatting Helpers

    public static func formatWh(_ wh: Double) -> String {
        if wh < 1 {
            return String(format: "%.1f mWh", wh * 1000)
        } else if wh < 1000 {
            return String(format: "%.1f Wh", wh)
        } else {
            return String(format: "%.2f kWh", wh / 1000)
        }
    }

    public static func formatCO2(_ grams: Double) -> String {
        if grams < 1 {
            return String(format: "%.1f mg", grams * 1000)
        } else if grams < 1000 {
            return String(format: "%.1f g", grams)
        } else {
            return String(format: "%.2f kg", grams / 1000)
        }
    }
}
