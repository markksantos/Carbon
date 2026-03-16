import Foundation

/// Persists energy samples to SQLite and provides daily/weekly aggregates.
public actor EnergyStore {
    private let db: SQLiteDatabase

    public init() async throws {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("Carbon")
        let dbPath = appSupport.appendingPathComponent("carbon.db").path
        self.db = try SQLiteDatabase(path: dbPath)
        try await db.execute("""
            CREATE TABLE IF NOT EXISTS energy_samples (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                app_name TEXT NOT NULL,
                bundle_id TEXT NOT NULL,
                timestamp REAL NOT NULL,
                cpu_watts REAL NOT NULL,
                gpu_watts REAL NOT NULL DEFAULT 0,
                duration_seconds REAL NOT NULL,
                region_code TEXT NOT NULL
            )
        """)
        try await db.execute("""
            CREATE INDEX IF NOT EXISTS idx_samples_timestamp ON energy_samples(timestamp)
        """)
    }

    public func recordSample(
        appName: String,
        bundleId: String,
        cpuWatts: Double,
        gpuWatts: Double,
        durationSeconds: Double,
        regionCode: String
    ) async {
        do {
            try await db.insert(
                """
                INSERT INTO energy_samples (app_name, bundle_id, timestamp, cpu_watts, gpu_watts, duration_seconds, region_code)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                params: [appName, bundleId, Date.now.timeIntervalSince1970, cpuWatts, gpuWatts, durationSeconds, regionCode]
            )
        } catch {
            print("Carbon: failed to record sample: \(error)")
        }
    }

    public func dailySummaries(for date: Date, carbonIntensity: Double) async -> [AppCarbonSummary] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date).timeIntervalSince1970
        let endOfDay = startOfDay + 86400

        do {
            let rows = try await db.query(
                """
                SELECT app_name, bundle_id,
                       SUM(cpu_watts * duration_seconds / 3600.0) as wh_cpu,
                       SUM(gpu_watts * duration_seconds / 3600.0) as wh_gpu
                FROM energy_samples
                WHERE timestamp >= ? AND timestamp < ?
                GROUP BY bundle_id
                ORDER BY (wh_cpu + wh_gpu) DESC
                """,
                params: [startOfDay, endOfDay]
            )
            return rows.compactMap { row in
                guard let name = row["app_name"],
                      let bundleId = row["bundle_id"],
                      let whCPU = row["wh_cpu"].flatMap(Double.init),
                      let whGPU = row["wh_gpu"].flatMap(Double.init)
                else { return nil }
                let totalWh = whCPU + whGPU
                let co2Grams = CarbonCalculator.co2Grams(wattHours: totalWh, intensity: carbonIntensity)
                return AppCarbonSummary(
                    appName: name,
                    bundleId: bundleId,
                    wattHours: totalWh,
                    co2Grams: co2Grams
                )
            }
        } catch {
            print("Carbon: daily query failed: \(error)")
            return []
        }
    }

    public func weeklyTotals(carbonIntensity: Double) async -> [DailyTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        let startTimestamp = weekAgo.timeIntervalSince1970

        do {
            let rows = try await db.query(
                """
                SELECT CAST((timestamp - ?) / 86400 AS INTEGER) as day_offset,
                       SUM(cpu_watts * duration_seconds / 3600.0) as wh_cpu,
                       SUM(gpu_watts * duration_seconds / 3600.0) as wh_gpu
                FROM energy_samples
                WHERE timestamp >= ?
                GROUP BY day_offset
                ORDER BY day_offset
                """,
                params: [startTimestamp, startTimestamp]
            )
            return rows.compactMap { row in
                guard let dayOffset = row["day_offset"].flatMap(Int.init),
                      let whCPU = row["wh_cpu"].flatMap(Double.init),
                      let whGPU = row["wh_gpu"].flatMap(Double.init)
                else { return nil }
                let date = calendar.date(byAdding: .day, value: dayOffset, to: weekAgo) ?? today
                let totalWh = whCPU + whGPU
                let co2 = CarbonCalculator.co2Grams(wattHours: totalWh, intensity: carbonIntensity)
                return DailyTotal(date: date, wattHours: totalWh, co2Grams: co2)
            }
        } catch {
            print("Carbon: weekly query failed: \(error)")
            return []
        }
    }
}

/// Aggregate energy/carbon for one calendar day (used in weekly charts).
public struct DailyTotal: Sendable, Identifiable {
    public let id: Date
    public let date: Date
    public let wattHours: Double
    public let co2Grams: Double

    public init(date: Date, wattHours: Double, co2Grams: Double) {
        self.id = date
        self.date = date
        self.wattHours = wattHours
        self.co2Grams = co2Grams
    }

    public var kWh: Double { wattHours / 1000.0 }
}
