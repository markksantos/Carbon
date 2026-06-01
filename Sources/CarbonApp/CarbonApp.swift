import SwiftUI
import CarbonUI
import CarbonEngine

@main
struct CarbonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            SettingsView(viewModel: delegate.viewModel)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = CarbonViewModel()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var welcomeWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Popover with vibrancy
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 0)
        popover.behavior = .transient
        popover.contentViewController = VibrancyHostingController(
            rootView: PopoverContentView(viewModel: viewModel)
        )

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "leaf.fill",
                accessibilityDescription: "Carbon"
            )
            button.imagePosition = .imageLeading
            button.title = " —"
            button.target = self
            button.action = #selector(statusBarClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Escape key closes popover
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53, self?.popover.isShown == true {
                self?.popover.performClose(nil)
                return nil
            }
            return event
        }

        // Sleep/wake observers
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self, selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )

        observeViewModel()

        if !WelcomeView.hasSeenWelcome {
            showWelcomeWindow()
        }
    }

    // MARK: - First-launch onboarding

    private func showWelcomeWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: WelcomeView { [weak self] in
            WelcomeView.hasSeenWelcome = true
            self?.welcomeWindow?.close()
            self?.welcomeWindow = nil
        })
        welcomeWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Sleep / Wake

    @objc private func handleSleep() {
        viewModel.pause()
    }

    @objc private func handleWake() {
        viewModel.resume()
    }

    // MARK: - Click handling

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Carbon", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Carbon", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil  // Clear so left-click works again
    }

    // MARK: - Menu actions

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Observation

    private func observeViewModel() {
        withObservationTracking {
            let watts = viewModel.totalWatts
            statusItem?.button?.title = watts > 0
                ? String(format: " %.0f W", watts)
                : " —"
        } onChange: {
            Task { @MainActor [weak self] in
                self?.observeViewModel()
            }
        }
    }
}

// MARK: - Vibrancy Hosting Controller

private final class VibrancyHostingController<Content: View>: NSHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()

        let vibrancy = NSVisualEffectView()
        vibrancy.material = .popover
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active
        vibrancy.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(vibrancy, positioned: .below, relativeTo: view.subviews.first)
        NSLayoutConstraint.activate([
            vibrancy.topAnchor.constraint(equalTo: view.topAnchor),
            vibrancy.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            vibrancy.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vibrancy.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
