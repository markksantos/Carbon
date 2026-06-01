import SwiftUI

/// First-launch onboarding panel. Explains what Carbon measures and its
/// privacy posture (local-only, no network), then dismisses itself. Shown
/// once, gated by `WelcomeView.hasSeenWelcome` in UserDefaults.
public struct WelcomeView: View {
    private let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("Welcome to Carbon")
                    .font(.title2.weight(.semibold))
                Text("Real-time energy & carbon tracking, right in your menu bar.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(
                    icon: "bolt.fill",
                    title: "Per-app wattage",
                    detail: "Samples CPU and GPU activity every few seconds and estimates watts from your chip's TDP."
                )
                FeatureRow(
                    icon: "leaf.arrow.circlepath",
                    title: "Carbon footprint",
                    detail: "Converts energy to CO\u{2082} using your region's grid intensity. Change the region in Settings."
                )
                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Private by design",
                    detail: "Everything stays on this Mac. No network access, no telemetry, no accounts."
                )
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 380, height: 460)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

extension WelcomeView {
    private static let defaultsKey = "com.nosleeplab.Carbon.hasSeenWelcome"

    /// Whether the welcome panel has already been shown.
    public static var hasSeenWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }
}
