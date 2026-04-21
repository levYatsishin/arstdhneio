#if os(macOS)
import XCTest
@testable import arstdhneio

final class AppConfigurationTests: XCTestCase {
    func testLoadsPersistedColemakSettingsWhenNoOverridesExist() {
        let userDefaults = makeUserDefaults()
        StoredAppSettingsStore(userDefaults: userDefaults).save(
            StoredAppSettings(layoutMode: .colemak5, customRowsText: "")
        )

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.gridLayout.columns, 5)
        XCTAssertEqual(configuration.storedSettings.layoutMode, .colemak5)
        XCTAssertFalse(configuration.usesLaunchOverrides)
    }

    func testLaunchArgumentOverridesPersistedSettings() {
        let userDefaults = makeUserDefaults()
        StoredAppSettingsStore(userDefaults: userDefaults).save(
            StoredAppSettings(layoutMode: .colemak5, customRowsText: "")
        )

        let configuration = AppConfiguration.load(
            arguments: ["arstdhneio", "--grid-keymap", "qwerty"],
            environment: [:],
            userDefaults: userDefaults
        )

        XCTAssertEqual(configuration.gridLayout.columns, 10)
        XCTAssertEqual(configuration.gridLayout.coordinate(for: "q"), GridCoordinate(row: 1, column: 0))
        XCTAssertTrue(configuration.usesLaunchOverrides)
    }

    func testCustomRowsPersistAndRoundTrip() {
        let userDefaults = makeUserDefaults()
        let settings = StoredAppSettings(layoutMode: .custom, customRowsText: "neiuy,qwfpg,arstd,zxcvb")

        StoredAppSettingsStore(userDefaults: userDefaults).save(settings)
        let loaded = StoredAppSettingsStore(userDefaults: userDefaults).load()

        XCTAssertEqual(loaded, settings)
        XCTAssertEqual(loaded.gridLayout()?.columns, 5)
        XCTAssertNil(loaded.validationError)
    }

    func testInvalidCustomRowsProduceValidationError() {
        let settings = StoredAppSettings(layoutMode: .custom, customRowsText: "abc,def")

        XCTAssertNotNil(settings.validationError)
        XCTAssertNil(settings.gridLayout())
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "arstdhneio.tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
#endif
