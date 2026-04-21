import Foundation

#if os(macOS)
import Carbon

protocol CommandKeyResolving {
    func printableCharacter(for keyCode: Int64, shift: Bool) -> Character?
}

struct CommandKeyMap: CommandKeyResolving {
    typealias Translator = (_ keyCode: UInt16, _ modifierState: UInt32) -> String?

    private let translator: Translator

    init(translator: @escaping Translator = SystemCommandKeyTranslator.translate) {
        self.translator = translator
    }

    func printableCharacter(for keyCode: Int64, shift: Bool) -> Character? {
        guard let keyCode = UInt16(exactly: keyCode) else { return nil }
        return translator(keyCode, Self.modifierState(includeShift: shift))?.first
    }

    static func modifierState(includeShift: Bool) -> UInt32 {
        let carbonModifiers = cmdKey | (includeShift ? shiftKey : 0)
        return UInt32(carbonModifiers >> 8)
    }
}

private enum SystemCommandKeyTranslator {
    static func translate(keyCode: UInt16, modifierState: UInt32, layoutData: CFData) -> String? {
        let keyboardType = UInt32(LMGetKbdType())
        let options = OptionBits(kUCKeyTranslateNoDeadKeysBit)
        var deadKeyState: UInt32 = 0
        var actualLength = 0
        var buffer = [UniChar](repeating: 0, count: 4)
        guard let layoutBytes = CFDataGetBytePtr(layoutData) else { return nil }
        let keyboardLayout = UnsafeRawPointer(layoutBytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDown),
            modifierState,
            keyboardType,
            options,
            &deadKeyState,
            buffer.count,
            &actualLength,
            &buffer
        )

        guard status == noErr, actualLength > 0 else { return nil }
        return String(utf16CodeUnits: buffer, count: Int(actualLength))
    }

    static func translate(keyCode: UInt16, modifierState: UInt32) -> String? {
        guard let layoutData = currentKeyboardLayoutData() else { return nil }
        return translate(keyCode: keyCode, modifierState: modifierState, layoutData: layoutData)
    }

    private static func currentKeyboardLayoutData() -> CFData? {
        keyboardLayoutData(from: TISCopyCurrentKeyboardLayoutInputSource()) ??
        keyboardLayoutData(from: TISCopyCurrentASCIICapableKeyboardLayoutInputSource())
    }

    private static func keyboardLayoutData(from inputSourceRef: Unmanaged<TISInputSource>?) -> CFData? {
        guard let inputSourceRef else { return nil }
        let inputSource = inputSourceRef.takeRetainedValue()
        let property = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
        guard let property else { return nil }
        return unsafeBitCast(property, to: CFData?.self)
    }
}
#endif
