import SwiftUI
import CarbonUI

@main
struct CarbonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var viewModel = CarbonViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(viewModel: viewModel)
        } label: {
            Label {
                Text(viewModel.totalWatts > 0
                     ? String(format: "%.0f W", viewModel.totalWatts)
                     : "—")
                    .monospacedDigit()
            } icon: {
                Image(systemName: "leaf.fill")
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
