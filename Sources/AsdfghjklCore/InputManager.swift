import Foundation
#if os(macOS)
import AppKit
import ApplicationServices
import CoreGraphics
#endif

public final class InputManager {
    private let overlayController: OverlayController
    private var commandRecognizer = CommandTapRecognizer()
    #if os(macOS)
    private struct PermissionStatus {
        let hasInputMonitoring: Bool
        let hasAccessibility: Bool

        var missingPermissions: [PermissionKind] {
            var missing: [PermissionKind] = []
            if !hasInputMonitoring {
                missing.append(.inputMonitoring)
            }
            if !hasAccessibility {
                missing.append(.accessibility)
            }
            return missing
        }
    }

    private enum PermissionKind {
        case inputMonitoring
        case accessibility

        var displayName: String {
            switch self {
            case .inputMonitoring:
                return "Input Monitoring"
            case .accessibility:
                return "Accessibility"
            }
        }

        var settingsURL: URL? {
            switch self {
            case .inputMonitoring:
                return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
            case .accessibility:
                return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }
        }
    }

    private let commandKeyResolver: any CommandKeyResolving
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var commandKeyIsDown = false
    #endif
    public var onToggle: (() -> Void)?

    public init(overlayController: OverlayController) {
        self.overlayController = overlayController
        #if os(macOS)
        self.commandKeyResolver = CommandKeyMap()
        #endif
    }

    #if os(macOS)
    init(overlayController: OverlayController, commandKeyResolver: any CommandKeyResolving) {
        self.overlayController = overlayController
        self.commandKeyResolver = commandKeyResolver
    }
    #endif

    public func start() {
        #if os(macOS)
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<InputManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            Task { @MainActor in
                InputManager.presentGlobalMonitoringAlert(permissionStatus: InputManager.currentPermissionStatus())
            }
            return
        }

        self.eventTap = eventTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        #else
        print("InputManager stub active (non-macOS environment)")
        #endif
    }

    public func stop() {
        #if os(macOS)
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        #endif
    }

    public func handleCommandDown() {
        commandRecognizer.handleCommandDown()
    }

    public func handleCommandUp() {
        commandRecognizer.handleCommandUp { [weak self] in
            self?.onToggle?()
            self?.overlayController.toggle()
        }
    }

    public func markCommandAsModifier() {
        commandRecognizer.handleCommandModifierUse()
    }

    @discardableResult
    public func handleKeyPress(_ key: Character) -> GridRect? {
        overlayController.handleKey(key)
    }

    public func handleSpacebarClick() {
        overlayController.click()
    }

    public func handleMiddleClick() {
        overlayController.middleClick()
    }

    public func handleRightClick() {
        overlayController.rightClick()
    }

    public func cancelOverlay() {
        overlayController.cancel()
    }

    /// Handles a key down event, performing refinement and click/cancel commands when the overlay is active.
    /// - Parameters:
    ///   - key: The pressed character.
    ///   - commandActive: Whether the Command modifier is currently held down.
    /// - Returns: `true` if the event was consumed by the overlay controller, `false` otherwise.
    @discardableResult
    public func handleKeyDown(_ key: Character, commandActive: Bool = false) -> Bool {
        if commandActive {
            markCommandAsModifier()
        }

        guard overlayController.isActive else { return false }

        if key == "\u{1b}" { // Escape
            cancelOverlay()
            return true
        }

        if key == " " { // Space
            handleSpacebarClick()
            return true
        }

        if key == "'" { // Apostrophe for middle click
            handleMiddleClick()
            return true
        }

        if key == "\\" { // Backslash for right click
            handleRightClick()
            return true
        }
        
        if key == "\u{7f}" { // Backspace/Delete
            return overlayController.zoomOut()
        }

        return handleKeyPress(key) != nil
    }

    #if os(macOS)
    private enum KeyDownResolution {
        case character(Character)
        case consumed
        case ignored
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        case .flagsChanged:
            let commandIsDown = event.flags.contains(.maskCommand)
            if commandIsDown && !commandKeyIsDown {
                handleCommandDown()
            } else if !commandIsDown && commandKeyIsDown {
                handleCommandUp()
            }
            commandKeyIsDown = commandIsDown
        case .keyDown:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let consumed = handleKeyCodeDown(keyCode, flags: event.flags)
            if consumed {
                return nil
            }
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    @discardableResult
    public func handleKeyCodeDown(_ keyCode: Int64, flags: CGEventFlags = []) -> Bool {
        switch keyDownResolution(for: keyCode, flags: flags) {
        case .character(let character):
            return handleKeyDown(character, commandActive: flags.contains(.maskCommand))
        case .consumed:
            return true
        case .ignored:
            if flags.contains(.maskCommand) {
                markCommandAsModifier()
            }
            return false
        }
    }
    
    private func keyDownResolution(for keyCode: Int64, flags: CGEventFlags) -> KeyDownResolution {
        switch keyCode {
        case 51:
            return .character("\u{7f}")
        case 49:
            return .character(" ")
        case 53:
            return .character("\u{1b}")
        default:
            break
        }

        if let direction = arrowDirection(for: keyCode), overlayController.isActive {
            return overlayController.moveSelection(direction) ? .consumed : .ignored
        }

        let shiftIsDown = flags.contains(.maskShift)
        if let printable = commandKeyResolver.printableCharacter(for: keyCode, shift: shiftIsDown) {
            return .character(printable)
        }

        return .ignored
    }

    private func arrowDirection(for keyCode: Int64) -> OverlayController.ArrowDirection? {
        switch keyCode {
        case 126: // Up arrow
            return .up
        case 125: // Down arrow
            return .down
        case 123: // Left arrow
            return .left
        case 124: // Right arrow
            return .right
        default:
            return nil
        }
    }

    @MainActor
    private static func presentGlobalMonitoringAlert(permissionStatus: PermissionStatus) {
        let alert = NSAlert()
        alert.alertStyle = .warning

        if permissionStatus.missingPermissions.isEmpty {
            alert.messageText = "Unable to start double-Command activation"
            alert.informativeText = "arstdhneio could not install the global keyboard listener required for Double-Command activation. If you just reinstalled or rebuilt the app bundle, remove any old arstdhneio entries from Privacy & Security, re-add the current app bundle, and relaunch it."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let missingNames = permissionStatus.missingPermissions.map(\.displayName).joined(separator: " and ")
        alert.messageText = "Enable \(missingNames)"
        alert.informativeText = "Double-Command activation uses a global keyboard listener. To use this mode, grant arstdhneio access under System Settings > Privacy & Security > \(missingNames), then relaunch the app."

        for permission in permissionStatus.missingPermissions {
            alert.addButton(withTitle: "Open \(permission.displayName)")
        }
        alert.addButton(withTitle: "OK")

        let response = alert.runModal()
        let permissionButtons = permissionStatus.missingPermissions
        let buttonIndex = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        guard buttonIndex >= 0, buttonIndex < permissionButtons.count else { return }

        if let url = permissionButtons[Int(buttonIndex)].settingsURL {
            NSWorkspace.shared.open(url)
        }
    }

    private static func currentPermissionStatus() -> PermissionStatus {
        PermissionStatus(
            hasInputMonitoring: CGPreflightListenEventAccess(),
            hasAccessibility: AXIsProcessTrusted()
        )
    }
    #endif
}
