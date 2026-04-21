import Foundation
#if os(macOS)
import SwiftUI
import AppKit
import arstdhneioCore

@MainActor
final class OverlayWindowController {
    private let screen: NSScreen
    private let model: OverlayVisualModel
    private let gridSlice: GridSlice
    private let handlesKeyboardInput: Bool
    private let keyDownHandler: ((NSEvent) -> Bool)?
    private var window: NSWindow?
    
    var windowID: CGWindowID? {
        guard let window else { return nil }
        let windowNumber = window.windowNumber
        return windowNumber >= 0 ? CGWindowID(windowNumber) : nil
    }

    init(
        screen: NSScreen,
        model: OverlayVisualModel,
        gridSlice: GridSlice,
        handlesKeyboardInput: Bool = false,
        keyDownHandler: ((NSEvent) -> Bool)? = nil
    ) {
        self.screen = screen
        self.model = model
        self.gridSlice = gridSlice
        self.handlesKeyboardInput = handlesKeyboardInput
        self.keyDownHandler = keyDownHandler
    }

    func show() {
        if window == nil {
            window = makeWindow()
        }
        window?.setFrame(screen.frame, display: true)
        if handlesKeyboardInput {
            window?.makeKeyAndOrderFront(nil)
        } else {
            window?.orderFrontRegardless()
        }
    }

    func hide() {
        window?.orderOut(nil)
    }

    func focusForKeyboardInput() {
        guard handlesKeyboardInput else { return }
        if window == nil {
            window = makeWindow()
        }
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let overlayView = OverlayGridView(
            model: model,
            screen: screen,
            gridSlice: gridSlice
        )
        let hosting = NSHostingController(rootView: overlayView)
        let window = OverlayInputWindow(contentViewController: hosting)
        window.keyDownHandler = keyDownHandler
        window.canBecomeKeyOverride = handlesKeyboardInput
        window.setFrame(screen.frame, display: true)
        window.styleMask = [.borderless]
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        return window
    }
}

private final class OverlayInputWindow: NSWindow {
    var keyDownHandler: ((NSEvent) -> Bool)?
    var canBecomeKeyOverride = false

    override var canBecomeKey: Bool {
        canBecomeKeyOverride
    }

    override var canBecomeMain: Bool {
        canBecomeKeyOverride
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, keyDownHandler?(event) == true {
            return
        }

        super.sendEvent(event)
    }
}
#endif
