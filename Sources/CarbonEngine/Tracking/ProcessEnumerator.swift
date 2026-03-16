import Darwin

public struct ProcessSnapshot: Sendable {
    public let pid: Int32
    public let name: String
    public let totalUserTicks: UInt64
    public let totalSystemTicks: UInt64
}

public struct ProcessEnumerator: Sendable {
    public init() {}

    public func listAll() -> [ProcessSnapshot] {
        let estimatedCount = proc_listallpids(nil, 0)
        guard estimatedCount > 0 else { return [] }

        var pids = [Int32](repeating: 0, count: Int(estimatedCount))
        let byteSize = Int32(MemoryLayout<Int32>.size * pids.count)
        let actualCount = proc_listallpids(&pids, byteSize)
        guard actualCount > 0 else { return [] }

        var results: [ProcessSnapshot] = []
        results.reserveCapacity(Int(actualCount))

        let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)

        for i in 0..<Int(actualCount) {
            let pid = pids[i]
            guard pid > 0 else { continue }

            var info = proc_taskinfo()
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, taskInfoSize)
            guard ret == taskInfoSize else { continue }

            results.append(ProcessSnapshot(
                pid: pid,
                name: processName(for: pid),
                totalUserTicks: info.pti_total_user,
                totalSystemTicks: info.pti_total_system
            ))
        }
        return results
    }

    private func processName(for pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 1024)
        proc_name(pid, &buffer, UInt32(buffer.count))
        if let idx = buffer.firstIndex(of: 0) {
            let bytes = buffer[..<idx].map { UInt8(bitPattern: $0) }
            let name = String(decoding: bytes, as: UTF8.self)
            return name.isEmpty ? "pid:\(pid)" : name
        }
        return "pid:\(pid)"
    }
}
