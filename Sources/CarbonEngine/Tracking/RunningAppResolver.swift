import AppKit

/// Lightweight Sendable representation of a running NSRunningApplication.
public struct RunningApp: Sendable {
    public let pid: Int32
    public let bundleIdentifier: String?
    public let localizedName: String?
}

/// Snapshots NSWorkspace.runningApplications on the main actor,
/// producing a Sendable dictionary safe to pass to any actor.
@MainActor
public struct RunningAppResolver {
    public init() {}

    public func snapshot() -> [Int32: RunningApp] {
        var dict: [Int32: RunningApp] = [:]
        for app in NSWorkspace.shared.runningApplications {
            dict[app.processIdentifier] = RunningApp(
                pid: app.processIdentifier,
                bundleIdentifier: app.bundleIdentifier,
                localizedName: app.localizedName
            )
        }
        return dict
    }
}
