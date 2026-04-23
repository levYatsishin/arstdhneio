#if os(macOS)
import Carbon
import Foundation
import arstdhneioCore

final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let onHotKey: () -> Void
    private let hotKeyID = EventHotKeyID(signature: OSType(0x41525354), id: 1) // "ARST"
    private let commandKeyMap: CommandKeyMap
    private let activationHotKey: ActivationHotKey

    init(
        activationHotKey: ActivationHotKey = .default,
        commandKeyMap: CommandKeyMap = CommandKeyMap(),
        onHotKey: @escaping () -> Void
    ) {
        self.activationHotKey = activationHotKey
        self.commandKeyMap = commandKeyMap
        self.onHotKey = onHotKey
    }

    func start() {
        stop()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData, let event else { return noErr }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotKeyEvent(event)
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        let modifiers = activationHotKey.carbonModifiers
        let keyCode = commandKeyMap.keyCode(
            for: activationHotKey.keyCharacter,
            carbonModifiers: modifiers
        ) ?? UInt32(kVK_ANSI_Semicolon)

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr, hotKeyID.id == self.hotKeyID.id else {
            return status
        }

        onHotKey()
        return noErr
    }
}
#endif
