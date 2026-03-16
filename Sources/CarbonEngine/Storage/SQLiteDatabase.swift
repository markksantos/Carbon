import Foundation

#if canImport(SQLite3)
import SQLite3
#endif

public actor SQLiteDatabase {
    private nonisolated(unsafe) var db: OpaquePointer?

    public init(path: String) throws {
        let dir = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw DBError.openFailed(msg)
        }
        // WAL mode — use raw C call in init (actor not yet fully initialized)
        var walErr: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, &walErr) != SQLITE_OK {
            sqlite3_free(walErr)
        }
    }

    deinit {
        sqlite3_close(db)
    }

    public func execute(_ sql: String) throws {
        var err: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &err) == SQLITE_OK else {
            let msg = err.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(err)
            throw DBError.execFailed(msg)
        }
    }

    public func query(_ sql: String, params: [Any] = []) throws -> [[String: String]] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw DBError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }

        bindParams(stmt: stmt, params: params)

        var rows: [[String: String]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let colCount = sqlite3_column_count(stmt)
            var row: [String: String] = [:]
            for i in 0..<colCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                if let text = sqlite3_column_text(stmt, i) {
                    row[name] = String(cString: text)
                }
            }
            rows.append(row)
        }
        return rows
    }

    public func insert(_ sql: String, params: [Any] = []) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw DBError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }

        bindParams(stmt: stmt, params: params)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw DBError.execFailed(msg)
        }
    }

    private func bindParams(stmt: OpaquePointer?, params: [Any]) {
        for (i, param) in params.enumerated() {
            let idx = Int32(i + 1)
            switch param {
            case let v as String:
                sqlite3_bind_text(stmt, idx, (v as NSString).utf8String, -1, nil)
            case let v as Double:
                sqlite3_bind_double(stmt, idx, v)
            case let v as Int:
                sqlite3_bind_int64(stmt, idx, Int64(v))
            case let v as Int64:
                sqlite3_bind_int64(stmt, idx, v)
            default:
                sqlite3_bind_null(stmt, idx)
            }
        }
    }

    public enum DBError: Error, Sendable {
        case openFailed(String)
        case execFailed(String)
        case prepareFailed(String)
    }
}
