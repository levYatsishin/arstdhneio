#if os(macOS)
import XCTest
@testable import arstdhneio

final class AppConfigurationTests: XCTestCase {
    func testLoadsPersistedColemakSettingsWhenNoOverridesExist() {
        let userDefaults = makeUserDefaults()
        StoredAppSettingsStore(userDefaults: userDefaults).save(
            StoredAppSettings(
                activationMode: .commandSemicolon,
                activationKeyText: ";",
                activationUsesCommand: true,
                activationUsesOption: false,
                activationUsesControl: false,
                activationUsesShift: false,
                layoutMode: .colemak5,
                customRowsText: ""
            )
        )

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.gridLayout.columns, 5)
        XCTAssertEqual(configuration.storedSettings.layoutMode, .colemak5)
        XCTAssertEqual(configuration.effectiveSettings.activationMode, .commandSemicolon)
        XCTAssertEqual(configuration.effectiveSettings.activationHotKey.keyCharacter, ";")
        XCTAssertFalse(configuration.usesLaunchOverrides)
    }

    func testLaunchArgumentOverridesPersistedSettings() {
        let userDefaults = makeUserDefaults()
        StoredAppSettingsStore(userDefaults: userDefaults).save(
            StoredAppSettings(
                activationMode: .commandSemicolon,
                activationKeyText: ";",
                activationUsesCommand: true,
                activationUsesOption: false,
                activationUsesControl: false,
                activationUsesShift: false,
                layoutMode: .colemak5,
                customRowsText: ""
            )
        )

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio", "--grid-keymap", "qwerty"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.gridLayout.columns, 10)
        XCTAssertEqual(configuration.gridLayout.coordinate(for: "q"), GridCoordinate(row: 1, column: 0))
        XCTAssertEqual(configuration.effectiveSettings.layoutMode, .qwerty)
        XCTAssertEqual(configuration.effectiveSettings.activationHotKey.keyCharacter, ";")
        XCTAssertTrue(configuration.usesLaunchOverrides)
    }

    func testCustomRowsPersistAndRoundTrip() {
        let userDefaults = makeUserDefaults()
        let settings = StoredAppSettings(
            activationMode: .doubleCommandTap,
            activationKeyText: "y",
            activationUsesCommand: true,
            activationUsesOption: false,
            activationUsesControl: false,
            activationUsesShift: false,
            layoutMode: .custom,
            customRowsText: "neiuy,qwfpg,arstd,zxcvb"
        )

        StoredAppSettingsStore(userDefaults: userDefaults).save(settings)
        let loaded = StoredAppSettingsStore(userDefaults: userDefaults).load()

        XCTAssertEqual(loaded, settings)
        XCTAssertEqual(loaded.gridLayout()?.columns, 5)
        XCTAssertNil(loaded.validationError)
    }

    func testInvalidCustomRowsProduceValidationError() {
        let settings = StoredAppSettings(
            activationMode: .commandSemicolon,
            activationKeyText: ";",
            activationUsesCommand: true,
            activationUsesOption: false,
            activationUsesControl: false,
            activationUsesShift: false,
            layoutMode: .custom,
            customRowsText: "abc,def"
        )

        XCTAssertNotNil(settings.validationError)
        XCTAssertNil(settings.gridLayout())
    }

    func testActivationModeOverrideUsesEffectiveSettingsWithoutChangingStoredSettings() {
        let userDefaults = makeUserDefaults()
        let stored = StoredAppSettings(
            activationMode: .doubleCommandTap,
            activationKeyText: "k",
            activationUsesCommand: true,
            activationUsesOption: false,
            activationUsesControl: false,
            activationUsesShift: false,
            layoutMode: .colemak5,
            customRowsText: ""
        )
        StoredAppSettingsStore(userDefaults: userDefaults).save(stored)

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio", "--activation-mode", "commandSemicolon"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.storedSettings.activationMode, .doubleCommandTap)
        XCTAssertEqual(configuration.effectiveSettings.activationMode, .commandSemicolon)
        XCTAssertEqual(configuration.effectiveSettings.activationHotKey.keyCharacter, "k")
        XCTAssertTrue(configuration.usesLaunchOverrides)
    }

    func testActivationKeyPersistsAndCanBeOverriddenForSingleLaunch() {
        let userDefaults = makeUserDefaults()
        let stored = StoredAppSettings(
            activationMode: .commandSemicolon,
            activationKeyText: "y",
            activationUsesCommand: true,
            activationUsesOption: false,
            activationUsesControl: false,
            activationUsesShift: false,
            layoutMode: .qwerty,
            customRowsText: ""
        )
        StoredAppSettingsStore(userDefaults: userDefaults).save(stored)

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio", "--activation-key", "o"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.storedSettings.activationHotKey.keyCharacter, "y")
        XCTAssertEqual(configuration.effectiveSettings.activationHotKey.keyCharacter, "o")
        XCTAssertEqual(configuration.effectiveSettings.activationHotKey.modifierDisplayText, "Command")
        XCTAssertTrue(configuration.usesLaunchOverrides)
    }

    func testActivationModifierOverrideUsesEffectiveShortcutWithoutChangingStoredShortcut() {
        let userDefaults = makeUserDefaults()
        let stored = StoredAppSettings(
            activationMode: .commandSemicolon,
            activationKeyText: "y",
            activationUsesCommand: true,
            activationUsesOption: false,
            activationUsesControl: false,
            activationUsesShift: false,
            layoutMode: .qwerty,
            customRowsText: ""
        )
        StoredAppSettingsStore(userDefaults: userDefaults).save(stored)

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio", "--activation-modifiers", "control,option"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.storedSettings.activationHotKey.modifierDisplayText, "Command")
        XCTAssertEqual(configuration.effectiveSettings.activationHotKey.modifierDisplayText, "Control+Option")
        XCTAssertTrue(configuration.usesLaunchOverrides)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "arstdhneio.tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
#endif
