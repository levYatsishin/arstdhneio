#if os(macOS)
import SwiftUI
import AppKit
import Carbon
import arstdhneioCore

private let appDebugLoggingEnabled = ProcessInfo.processInfo.environment["ARSTDHNEIO_DEBUG"] == "1"

private func appDebugLog(_ message: String) {
    guard appDebugLoggingEnabled else { return }
    fputs("[App] \(message)\n", stderr)
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("arstdhneio")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("A practical fork of Asdfghjkl.")
                    .font(.headline)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage:")
                        .font(.headline)
                    
                    Text("1. Press Cmd+; to show the keyboard grid")
                    Text("2. Tap a corresponding key to move the mouse to that area")
                    Text("3. Tap again (and again) to drill down")
                    Text("4. Tap Space at any point to click the mouse")
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("You can also:")
                        .font(.headline)
                    
                    Text("• Use Configuration to switch to Double-Command activation")
                    Text("• Tap Backspace to zoom back out to the previous level")
                    Text("• Tap Arrow Keys to move the selected tile")
                    Text("• Tap ' (apostrophe) to middle-click")
                    Text("• Tap \\ (backslash) to right-click")
                    Text("• Tap Esc to cancel and hide the overlay")
                }
                .padding(.vertical, 4)
                
                Link("GitHub: levYatsishin/arstdhneio",
                     destination: URL(string: "https://github.com/levYatsishin/arstdhneio")!)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                
                Text("Derived from Dave Hulbert's Asdfghjkl")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(width: 500, height: 450)
    }
}

@main
struct arstdhneioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let overlayVisualModel = OverlayVisualModel()
    private let settingsStore = StoredAppSettingsStore()
    private let launchAtLoginManager = LaunchAtLoginManager()
    private var appConfiguration = AppConfiguration.load()
    private var currentSettings = StoredAppSettings.default
    private var currentGridLayout = arstdhneioCore.GridLayout()
    private var currentActivationMode = ActivationMode.commandSemicolon
    private var overlayController: OverlayController!
    private var inputManager: InputManager!
    private var hotKeyManager: GlobalHotKeyManager?
    private var overlayWindows: [OverlayWindowController] = []
    private var screenRects: [GridRect] = [.defaultScreen]
    private var screenObserver: NSObjectProtocol?
    private var keyboardInputSourceObserver: NSObjectProtocol?
    private var statusItem: NSStatusItem?
    private var launchAtLoginMenuItem: NSMenuItem?
    private var aboutWindow: NSWindow?
    private var configurationWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        currentSettings = appConfiguration.effectiveSettings
        currentGridLayout = appConfiguration.gridLayout
        currentActivationMode = appConfiguration.effectiveSettings.activationMode
        appDebugLog("launch activationMode=\(currentActivationMode.rawValue) layoutColumns=\(currentGridLayout.columns)")
        setupMenuBar()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChange()
            }
        }

        keyboardInputSourceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleKeyboardInputSourceChange()
            }
        }

        configureRuntime(layout: appConfiguration.gridLayout, activationMode: appConfiguration.effectiveSettings.activationMode)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "⌨️"
        }
        
        let menu = NSMenu()
        menu.delegate = self
        
        let aboutMenuItem = NSMenuItem(
            title: "About arstdhneio",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)

        let configurationMenuItem = NSMenuItem(
            title: "Configuration...",
            action: #selector(showConfiguration),
            keyEquivalent: ","
        )
        configurationMenuItem.target = self
        menu.addItem(configurationMenuItem)

        let launchAtLoginMenuItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem.target = self
        menu.addItem(launchAtLoginMenuItem)
        self.launchAtLoginMenuItem = launchAtLoginMenuItem
        
        menu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        statusItem?.menu = menu
        refreshLaunchAtLoginMenuItem()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refreshLaunchAtLoginMenuItem()
    }

    private func refreshLaunchAtLoginMenuItem() {
        guard let launchAtLoginMenuItem else { return }

        switch launchAtLoginManager.status {
        case .unavailable:
            launchAtLoginMenuItem.title = "Launch at Login (requires arstdhneio.app)"
            launchAtLoginMenuItem.state = .off
            launchAtLoginMenuItem.isEnabled = false
        case .enabled:
            launchAtLoginMenuItem.title = "Launch at Login"
            launchAtLoginMenuItem.state = .on
            launchAtLoginMenuItem.isEnabled = true
        case .requiresApproval:
            launchAtLoginMenuItem.title = "Launch at Login (approve in Settings)"
            launchAtLoginMenuItem.state = .on
            launchAtLoginMenuItem.isEnabled = true
        case .notRegistered, .notFound:
            launchAtLoginMenuItem.title = "Launch at Login"
            launchAtLoginMenuItem.state = .off
            launchAtLoginMenuItem.isEnabled = true
        }
    }
    
    @objc private func showAbout() {
        if aboutWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "About arstdhneio"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: AboutView())
            aboutWindow = window
        }

        aboutWindow?.center()
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showConfiguration() {
        if configurationWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 560),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Configuration"
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 560, height: 560))
            window.minSize = NSSize(width: 560, height: 520)
            configurationWindow = window
        }

        configurationWindow?.contentView = NSHostingView(
            rootView: ConfigurationView(
                settings: currentSettings,
                usesLaunchOverrides: appConfiguration.usesLaunchOverrides,
                onSave: { [weak self] settings in
                    self?.saveConfiguration(settings)
                },
                onReset: { [weak self] in
                    self?.resetConfiguration()
                }
            )
        )
        configurationWindow?.center()
        configurationWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            _ = try launchAtLoginManager.toggle()
            refreshLaunchAtLoginMenuItem()
        } catch {
            refreshLaunchAtLoginMenuItem()
            presentLaunchAtLoginError(error)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        if let keyboardInputSourceObserver {
            DistributedNotificationCenter.default().removeObserver(keyboardInputSourceObserver)
        }
        hotKeyManager?.stop()
        inputManager.stop()
        overlayWindows.forEach { $0.hide() }
    }

    private func handleStateChange(_ state: OverlayState) {
        overlayVisualModel.apply(state: state)
        updateWindowVisibility(for: state)
    }
    
    private func updateWindowVisibility(for state: OverlayState) {
        appDebugLog("updateWindowVisibility active=\(state.isActive)")
        if state.isActive {
            overlayWindows.forEach { $0.show() }
            if currentActivationMode == .commandSemicolon {
                appDebugLog("requesting overlay keyboard focus")
                overlayWindows.first?.focusForKeyboardInput()
            }
        } else {
            overlayWindows.forEach { $0.hide() }
        }
    }

    private func rebuildOverlayWindows() {
        overlayWindows.forEach { $0.hide() }
        let screens = NSScreen.screens
        screenRects = screens.map { gridRect(for: $0) }
        let slices = GridPartitioner.slices(for: screenRects, layout: currentGridLayout)
        let gridSlices = slices.isEmpty ? GridPartitioner.slices(for: [.defaultScreen], layout: currentGridLayout) : slices

        overlayWindows = Array(zip(screens, gridSlices).enumerated()).map {
            OverlayWindowController(
                screen: $0.element.0,
                model: overlayVisualModel,
                gridSlice: $0.element.1,
                handlesKeyboardInput: currentActivationMode == .commandSemicolon && $0.offset == 0,
                keyDownHandler: currentActivationMode == .commandSemicolon ? { [weak self] event in
                    self?.handleOverlayKeyEvent(event) ?? false
                } : nil
            )
        }

        if overlayController.isActive {
            overlayWindows.forEach { $0.show() }
            if currentActivationMode == .commandSemicolon {
                overlayWindows.first?.focusForKeyboardInput()
            }
        }
    }

    private func handleScreenChange() {
        rebuildOverlayWindows()
    }

    private func gridRect(for screen: NSScreen) -> GridRect {
        let frame = screen.frame
        return GridRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height)
    }

    private func presentLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Unable to update Launch at Login"
        alert.informativeText = [error.localizedDescription, (error as? LocalizedError)?.recoverySuggestion]
            .compactMap { $0 }
            .joined(separator: "\n\n")
        alert.runModal()
    }

    private func configureRuntime(layout gridLayout: arstdhneioCore.GridLayout, activationMode: ActivationMode) {
        currentGridLayout = gridLayout
        currentActivationMode = activationMode
        appDebugLog("configureRuntime activationMode=\(activationMode.rawValue)")
        hotKeyManager?.stop()
        inputManager?.stop()
        overlayWindows.forEach { $0.hide() }

        overlayController = OverlayController(
            gridLayout: gridLayout,
            screenBoundsProvider: { [weak self] in
                guard let self else { return [.defaultScreen] }
                return self.screenRects
            },
            cursorPositionProvider: {
                guard let mouseLocation = CGEvent(source: nil)?.location else { return nil }
                return GridPoint(x: mouseLocation.x, y: mouseLocation.y)
            }
        )

        overlayController.stateDidChange = { [weak self] state in
            Task { @MainActor in
                self?.handleStateChange(state)
            }
        }

        inputManager = InputManager(overlayController: overlayController)
        if activationMode == .doubleCommandTap {
            appDebugLog("starting global input manager for double-command mode")
            inputManager.onToggle = { [weak self] in
                Task { @MainActor in
                    self?.rebuildOverlayWindows()
                }
            }
            inputManager.setDoubleCommandActivationEnabled(true)
            inputManager.start()
        } else {
            appDebugLog("starting cmd+; hotkey mode")
            inputManager.onToggle = nil
            inputManager.setDoubleCommandActivationEnabled(false)
            let hotKeyManager = GlobalHotKeyManager { [weak self] in
                Task { @MainActor in
                    self?.handleCommandSemicolonActivation()
                }
            }
            hotKeyManager.start()
            self.hotKeyManager = hotKeyManager
        }

        rebuildOverlayWindows()
    }

    private func saveConfiguration(_ settings: StoredAppSettings) {
        currentSettings = settings
        settingsStore.save(settings)

        if !appConfiguration.usesLaunchOverrides, let layout = settings.gridLayout() {
            appConfiguration = AppConfiguration(
                gridLayout: layout,
                storedSettings: settings,
                effectiveSettings: settings,
                usesLaunchOverrides: false
            )
            configureRuntime(layout: layout, activationMode: settings.activationMode)
        }
    }

    private func resetConfiguration() {
        saveConfiguration(.default)
    }

    private func handleCommandSemicolonActivation() {
        appDebugLog("cmd+; activation received overlayActive=\(overlayController.isActive)")
        rebuildOverlayWindows()
        overlayController.toggle()
    }

    private func handleKeyboardInputSourceChange() {
        guard currentActivationMode == .commandSemicolon else { return }
        hotKeyManager?.start()
    }

    private func handleOverlayKeyEvent(_ event: NSEvent) -> Bool {
        let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
        let consumed = inputManager.handleKeyCodeDown(Int64(event.keyCode), flags: flags)
        appDebugLog(
            "overlay keyDown keyCode=\(event.keyCode) chars=\(event.charactersIgnoringModifiers ?? "nil") " +
            "mods=\(event.modifierFlags.rawValue) consumed=\(consumed) overlayActive=\(overlayController.isActive)"
        )
        return consumed
    }
}
#else
import Foundation
import arstdhneioCore

@main
struct arstdhneioApp {
    static func main() {
        let overlayController = OverlayController()
        let inputManager = InputManager(overlayController: overlayController)
        inputManager.start()
    }
}
#endif
