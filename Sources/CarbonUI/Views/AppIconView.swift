import SwiftUI

public struct AppIconView: View {
    let bundleIdentifier: String?

    @MainActor private static let iconCache = NSCache<NSString, NSImage>()

    public init(bundleIdentifier: String?) {
        self.bundleIdentifier = bundleIdentifier
    }

    public var body: some View {
        if let icon = resolveIcon() {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func resolveIcon() -> NSImage? {
        guard let bundleId = bundleIdentifier else { return nil }
        let key = bundleId as NSString

        if let cached = Self.iconCache.object(forKey: key) {
            return cached
        }

        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        Self.iconCache.setObject(icon, forKey: key)
        return icon
    }
}
