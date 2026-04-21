import XCTest
#if os(macOS)
import Carbon
@testable import arstdhneioCore

final class CommandKeyMapTests: XCTestCase {
    func testModifierStateAlwaysIncludesCommand() {
        XCTAssertEqual(CommandKeyMap.modifierState(includeShift: false), UInt32(cmdKey >> 8))
        XCTAssertEqual(CommandKeyMap.modifierState(includeShift: true), UInt32((cmdKey | shiftKey) >> 8))
    }

    func testPrintableCharacterUsesCommandEquivalentTranslator() {
        var recordedKeyCode: UInt16?
        var recordedModifierState: UInt32?
        let map = CommandKeyMap { keyCode, modifierState in
            recordedKeyCode = keyCode
            recordedModifierState = modifierState
            return "n"
        }

        let character = map.printableCharacter(for: 38, shift: true)

        XCTAssertEqual(character, "n")
        XCTAssertEqual(recordedKeyCode, 38)
        XCTAssertEqual(recordedModifierState, CommandKeyMap.modifierState(includeShift: true))
    }

    func testPrintableCharacterRejectsOutOfRangeKeyCode() {
        let map = CommandKeyMap { _, _ in
            XCTFail("translator should not be called for invalid key codes")
            return nil
        }

        XCTAssertNil(map.printableCharacter(for: -1, shift: false))
        XCTAssertNil(map.printableCharacter(for: Int64(UInt16.max) + 1, shift: false))
    }

    func testKeyBindingPrefersNonShiftMatch() {
        let map = CommandKeyMap { keyCode, modifierState in
            switch (keyCode, modifierState) {
            case (17, CommandKeyMap.modifierState(includeShift: false)):
                return ";"
            case (18, CommandKeyMap.modifierState(includeShift: true)):
                return ";"
            default:
                return nil
            }
        }

        XCTAssertEqual(map.keyBinding(for: ";"), CommandKeyBinding(keyCode: 17, requiresShift: false))
    }

    func testKeyBindingFallsBackToShiftMatch() {
        let map = CommandKeyMap { keyCode, modifierState in
            switch (keyCode, modifierState) {
            case (18, CommandKeyMap.modifierState(includeShift: true)):
                return ";"
            default:
                return nil
            }
        }

        XCTAssertEqual(map.keyBinding(for: ";"), CommandKeyBinding(keyCode: 18, requiresShift: true))
    }
}
#endif
