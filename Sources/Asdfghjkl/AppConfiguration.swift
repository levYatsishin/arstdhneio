#if os(macOS)
import Foundation
import arstdhneioCore

enum GridLayoutMode: String, CaseIterable, Sendable {
    case qwerty
    case colemak
    case colemak5
    case custom

    var displayName: String {
        switch self {
        case .qwerty:
            return "QWERTY"
        case .colemak:
            return "Colemak"
        case .colemak5:
            return "Colemak 5x4"
        case .custom:
            return "Custom"
        }
    }

    var preset: GridLayoutPreset? {
        switch self {
        case .qwerty:
            return .qwerty
        case .colemak:
            return .colemak
        case .colemak5:
            return .colemak5
        case .custom:
            return nil
        }
    }

    init(preset: GridLayoutPreset) {
        switch preset {
        case .qwerty:
            self = .qwerty
        case .colemak:
            self = .colemak
        case .colemak5:
            self = .colemak5
        }
    }
}

enum ActivationMode: String, CaseIterable, Sendable {
    case commandSemicolon
    case doubleCommandTap

    var displayName: String {
        switch self {
        case .commandSemicolon:
            return "Cmd+; (Recommended)"
        case .doubleCommandTap:
            return "Double-Command Tap"
        }
    }

    var descriptionText: String {
        switch self {
        case .commandSemicolon:
            return "Uses a registered global shortcut for activation while overlay keys still flow through the global listener. This mode still requires Input Monitoring and Accessibility."
        case .doubleCommandTap:
            return "Uses a global event tap to detect a double tap of Command. This mode requires Input Monitoring in addition to Accessibility."
        }
    }
}

struct StoredAppSettings: Equatable, Sendable {
    var activationMode: ActivationMode
    var layoutMode: GridLayoutMode
    var customRowsText: String

    static let `default` = StoredAppSettings(
        activationMode: .commandSemicolon,
        layoutMode: .qwerty,
        customRowsText: ""
    )

    var trimmedCustomRowsText: String {
        customRowsText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var effectiveRowStrings: [String] {
        if let preset = layoutMode.preset {
            return preset.rowStrings
        }

        return trimmedCustomRowsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func gridLayout() -> GridLayout? {
        if let preset = layoutMode.preset {
            return GridLayout(preset: preset)
        }

        let rows = effectiveRowStrings
        guard rows.count == 4 else { return nil }
        return GridLayout(rowStrings: rows)
    }

    var validationError: String? {
        if layoutMode != .custom {
            return nil
        }

        let rows = effectiveRowStrings
        guard !rows.isEmpty else {
            return "Enter four comma-separated custom rows."
        }

        guard rows.count == 4 else {
            return "Custom layouts must contain exactly four comma-separated rows."
        }

        guard GridLayout(rowStrings: rows) != nil else {
            return "Custom rows must form a valid 4x5 or 4x10 layout with equal-width rows and no duplicate characters."
        }

        return nil
    }

    static func from(layout: GridLayout) -> StoredAppSettings {
        if let preset = GridLayoutPreset.allCases.first(where: { $0.rowStrings == layout.rowStrings }) {
            return StoredAppSettings(
                activationMode: .commandSemicolon,
                layoutMode: GridLayoutMode(preset: preset),
                customRowsText: ""
            )
        }

        return StoredAppSettings(
            activationMode: .commandSemicolon,
            layoutMode: .custom,
            customRowsText: layout.rowStrings.joined(separator: ",")
        )
    }
}

struct AppConfiguration {
    let gridLayout: GridLayout
    let storedSettings: StoredAppSettings
    let effectiveSettings: StoredAppSettings
    let usesLaunchOverrides: Bool

    static func load(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        userDefaults: UserDefaults = .standard
    ) -> AppConfiguration {
        let storedSettings = StoredAppSettingsStore(userDefaults: userDefaults).load()
        let activationArgument = argumentValue(named: "--activation-mode", in: arguments) ?? environment["ARSTDHNEIO_ACTIVATION_MODE"]
        let layoutArgument = argumentValue(named: "--grid-keymap", in: arguments) ?? environment["ARSTDHNEIO_GRID_KEYMAP"] ?? environment["ASDFGHJKL_GRID_KEYMAP"]
        let rowsArgument = argumentValue(named: "--grid-key-rows", in: arguments) ?? environment["ARSTDHNEIO_GRID_KEY_ROWS"] ?? environment["ASDFGHJKL_GRID_KEY_ROWS"]
        let activationMode = ActivationMode(rawValue: activationArgument ?? "") ?? storedSettings.activationMode

        if let rowsArgument,
           let layout = GridLayout(rowStrings: rowsArgument.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            var effectiveSettings = StoredAppSettings.from(layout: layout)
            effectiveSettings.activationMode = activationMode
            return AppConfiguration(
                gridLayout: layout,
                storedSettings: storedSettings,
                effectiveSettings: effectiveSettings,
                usesLaunchOverrides: true
            )
        }

        if let layoutArgument,
           let preset = GridLayoutPreset(rawValue: layoutArgument.lowercased()) {
            let layout = GridLayout(preset: preset)
            var effectiveSettings = StoredAppSettings.from(layout: layout)
            effectiveSettings.activationMode = activationMode
            return AppConfiguration(
                gridLayout: layout,
                storedSettings: storedSettings,
                effectiveSettings: effectiveSettings,
                usesLaunchOverrides: true
            )
        }

        if activationArgument != nil {
            return AppConfiguration(
                gridLayout: storedSettings.gridLayout() ?? GridLayout(),
                storedSettings: storedSettings,
                effectiveSettings: StoredAppSettings(
                    activationMode: activationMode,
                    layoutMode: storedSettings.layoutMode,
                    customRowsText: storedSettings.customRowsText
                ),
                usesLaunchOverrides: true
            )
        }

        return AppConfiguration(
            gridLayout: storedSettings.gridLayout() ?? GridLayout(),
            storedSettings: storedSettings,
            effectiveSettings: storedSettings,
            usesLaunchOverrides: false
        )
    }

    private static func argumentValue(named name: String, in arguments: [String]) -> String? {
        if let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }

        let prefix = "\(name)="
        return arguments.first(where: { $0.hasPrefix(prefix) })?.dropFirst(prefix.count).description
    }
}

struct StoredAppSettingsStore {
    private enum Keys {
        static let activationMode = "app.activationMode"
        static let layoutMode = "app.layoutMode"
        static let customRows = "app.customRows"
    }

    let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> StoredAppSettings {
        let activationMode = ActivationMode(rawValue: userDefaults.string(forKey: Keys.activationMode) ?? "") ?? .commandSemicolon
        let mode = GridLayoutMode(rawValue: userDefaults.string(forKey: Keys.layoutMode) ?? "") ?? .qwerty
        let customRowsText = userDefaults.string(forKey: Keys.customRows) ?? ""
        return StoredAppSettings(activationMode: activationMode, layoutMode: mode, customRowsText: customRowsText)
    }

    func save(_ settings: StoredAppSettings) {
        userDefaults.set(settings.activationMode.rawValue, forKey: Keys.activationMode)
        userDefaults.set(settings.layoutMode.rawValue, forKey: Keys.layoutMode)
        userDefaults.set(settings.customRowsText, forKey: Keys.customRows)
    }
}

private extension GridLayout {
    var rowStrings: [String] {
        (0..<rows).map { row in
            String((0..<columns).compactMap { column in label(forRow: row, column: column) })
        }
    }
}
#endif
