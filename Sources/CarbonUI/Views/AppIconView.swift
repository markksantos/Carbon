import SwiftUI

public struct AppIconView: View {
    let bundleIdentifier: String?

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
        guard let bundleId = bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
        else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
