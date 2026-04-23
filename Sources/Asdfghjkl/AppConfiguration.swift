#if os(macOS)
import Foundation
import Carbon
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
            return "Shortcut (Recommended)"
        case .doubleCommandTap:
            return "Double-Command Tap"
        }
    }

    var descriptionText: String {
        switch self {
        case .commandSemicolon:
            return "Uses a registered global shortcut for activation and local overlay keyboard handling. Choose the modifiers and key below. This mode only needs Accessibility."
        case .doubleCommandTap:
            return "Uses a global event tap to detect a double tap of Command. This mode requires Input Monitoring in addition to Accessibility."
        }
    }
}

struct ActivationHotKey: Equatable, Sendable {
    var keyText: String
    var usesCommand: Bool
    var usesOption: Bool
    var usesControl: Bool
    var usesShift: Bool

    static let `default` = ActivationHotKey(
        keyText: ";",
        usesCommand: true,
        usesOption: false,
        usesControl: false,
        usesShift: false
    )

    var trimmedKeyText: String {
        keyText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var keyCharacter: Character {
        let trimmed = trimmedKeyText
        guard trimmed.count == 1, let character = trimmed.first else {
            return ";"
        }
        return character
    }

    var carbonModifiers: UInt32 {
        var modifiers: UInt32 = 0
        if usesCommand {
            modifiers |= UInt32(cmdKey)
        }
        if usesOption {
            modifiers |= UInt32(optionKey)
        }
        if usesControl {
            modifiers |= UInt32(controlKey)
        }
        if usesShift {
            modifiers |= UInt32(shiftKey)
        }
        return modifiers
    }

    var modifierDisplayText: String {
        let parts = [
            usesControl ? "Control" : nil,
            usesOption ? "Option" : nil,
            usesShift ? "Shift" : nil,
            usesCommand ? "Command" : nil,
        ].compactMap { $0 }

        return parts.joined(separator: "+")
    }

    var displayText: String {
        let modifierText = modifierDisplayText
        let keyText = trimmedKeyText.isEmpty ? "?" : trimmedKeyText.uppercased()
        guard !modifierText.isEmpty else { return keyText }
        return "\(modifierText)+\(keyText)"
    }

    var validationError: String? {
        let trimmedKeyText = trimmedKeyText
        guard !trimmedKeyText.isEmpty else {
            return "Enter a single key for the activation shortcut."
        }

        guard trimmedKeyText.count == 1 else {
            return "The activation shortcut key must use exactly one character."
        }

        guard usesCommand || usesOption || usesControl || usesShift else {
            return "Select at least one modifier for the activation shortcut."
        }

        return nil
    }
}

struct StoredAppSettings: Equatable, Sendable {
    var activationMode: ActivationMode
    var activationKeyText: String
    var activationUsesCommand: Bool
    var activationUsesOption: Bool
    var activationUsesControl: Bool
    var activationUsesShift: Bool
    var layoutMode: GridLayoutMode
    var customRowsText: String

    static let `default` = StoredAppSettings(
        activationMode: .commandSemicolon,
        activationKeyText: ActivationHotKey.default.keyText,
        activationUsesCommand: ActivationHotKey.default.usesCommand,
        activationUsesOption: ActivationHotKey.default.usesOption,
        activationUsesControl: ActivationHotKey.default.usesControl,
        activationUsesShift: ActivationHotKey.default.usesShift,
        layoutMode: .qwerty,
        customRowsText: ""
    )

    var trimmedCustomRowsText: String {
        customRowsText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var activationHotKey: ActivationHotKey {
        ActivationHotKey(
            keyText: activationKeyText,
            usesCommand: activationUsesCommand,
            usesOption: activationUsesOption,
            usesControl: activationUsesControl,
            usesShift: activationUsesShift
        )
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
        if activationMode == .commandSemicolon {
            if let activationError = activationHotKey.validationError {
                return activationError
            }
        }

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
                activationKeyText: ActivationHotKey.default.keyText,
                activationUsesCommand: ActivationHotKey.default.usesCommand,
                activationUsesOption: ActivationHotKey.default.usesOption,
                activationUsesControl: ActivationHotKey.default.usesControl,
                activationUsesShift: ActivationHotKey.default.usesShift,
                layoutMode: GridLayoutMode(preset: preset),
                customRowsText: ""
            )
        }

        return StoredAppSettings(
            activationMode: .commandSemicolon,
            activationKeyText: ActivationHotKey.default.keyText,
            activationUsesCommand: ActivationHotKey.default.usesCommand,
            activationUsesOption: ActivationHotKey.default.usesOption,
            activationUsesControl: ActivationHotKey.default.usesControl,
            activationUsesShift: ActivationHotKey.default.usesShift,
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
        let activationKeyArgument = argumentValue(named: "--activation-key", in: arguments) ?? environment["ARSTDHNEIO_ACTIVATION_KEY"]
        let activationModifiersArgument = argumentValue(named: "--activation-modifiers", in: arguments) ?? environment["ARSTDHNEIO_ACTIVATION_MODIFIERS"]
        let layoutArgument = argumentValue(named: "--grid-keymap", in: arguments) ?? environment["ARSTDHNEIO_GRID_KEYMAP"] ?? environment["ASDFGHJKL_GRID_KEYMAP"]
        let rowsArgument = argumentValue(named: "--grid-key-rows", in: arguments) ?? environment["ARSTDHNEIO_GRID_KEY_ROWS"] ?? environment["ASDFGHJKL_GRID_KEY_ROWS"]
        let activationMode = ActivationMode(rawValue: activationArgument ?? "") ?? storedSettings.activationMode
        let activationHotKey = resolvedActivationHotKey(
            keyArgument: activationKeyArgument,
            modifiersArgument: activationModifiersArgument,
            storedSettings: storedSettings
        )

        if let rowsArgument,
           let layout = GridLayout(rowStrings: rowsArgument.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            var effectiveSettings = StoredAppSettings.from(layout: layout)
            effectiveSettings.activationMode = activationMode
            effectiveSettings.activationKeyText = activationHotKey.keyText
            effectiveSettings.activationUsesCommand = activationHotKey.usesCommand
            effectiveSettings.activationUsesOption = activationHotKey.usesOption
            effectiveSettings.activationUsesControl = activationHotKey.usesControl
            effectiveSettings.activationUsesShift = activationHotKey.usesShift
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
            effectiveSettings.activationKeyText = activationHotKey.keyText
            effectiveSettings.activationUsesCommand = activationHotKey.usesCommand
            effectiveSettings.activationUsesOption = activationHotKey.usesOption
            effectiveSettings.activationUsesControl = activationHotKey.usesControl
            effectiveSettings.activationUsesShift = activationHotKey.usesShift
            return AppConfiguration(
                gridLayout: layout,
                storedSettings: storedSettings,
                effectiveSettings: effectiveSettings,
                usesLaunchOverrides: true
            )
        }

        if activationArgument != nil || activationKeyArgument != nil || activationModifiersArgument != nil {
            return AppConfiguration(
                gridLayout: storedSettings.gridLayout() ?? GridLayout(),
                storedSettings: storedSettings,
                effectiveSettings: StoredAppSettings(
                    activationMode: activationMode,
                    activationKeyText: activationHotKey.keyText,
                    activationUsesCommand: activationHotKey.usesCommand,
                    activationUsesOption: activationHotKey.usesOption,
                    activationUsesControl: activationHotKey.usesControl,
                    activationUsesShift: activationHotKey.usesShift,
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

    private static func resolvedActivationHotKey(
        keyArgument: String?,
        modifiersArgument: String?,
        storedSettings: StoredAppSettings
    ) -> ActivationHotKey {
        var hotKey = storedSettings.activationHotKey

        if let keyArgument {
            let trimmed = keyArgument.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count == 1 {
                hotKey.keyText = trimmed
            }
        }

        if let modifiersArgument, let parsedModifiers = parseActivationModifiers(modifiersArgument) {
            hotKey.usesCommand = parsedModifiers.usesCommand
            hotKey.usesOption = parsedModifiers.usesOption
            hotKey.usesControl = parsedModifiers.usesControl
            hotKey.usesShift = parsedModifiers.usesShift
        }

        return hotKey
    }

    private static func parseActivationModifiers(_ value: String) -> ActivationHotKey? {
        let parts = value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }

        var hotKey = ActivationHotKey.default
        hotKey.usesCommand = false
        hotKey.usesOption = false
        hotKey.usesControl = false
        hotKey.usesShift = false

        for part in parts {
            switch part {
            case "cmd", "command":
                hotKey.usesCommand = true
            case "opt", "option", "alt":
                hotKey.usesOption = true
            case "ctrl", "control":
                hotKey.usesControl = true
            case "shift":
                hotKey.usesShift = true
            default:
                return nil
            }
        }

        return hotKey
    }
}

struct StoredAppSettingsStore {
    private enum Keys {
        static let activationMode = "app.activationMode"
        static let activationKey = "app.activationKey"
        static let activationUsesCommand = "app.activationUsesCommand"
        static let activationUsesOption = "app.activationUsesOption"
        static let activationUsesControl = "app.activationUsesControl"
        static let activationUsesShift = "app.activationUsesShift"
        static let layoutMode = "app.layoutMode"
        static let customRows = "app.customRows"
    }

    let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> StoredAppSettings {
        let activationMode = ActivationMode(rawValue: userDefaults.string(forKey: Keys.activationMode) ?? "") ?? .commandSemicolon
        let activationKeyText = userDefaults.string(forKey: Keys.activationKey) ?? ActivationHotKey.default.keyText
        let activationUsesCommand = userDefaults.object(forKey: Keys.activationUsesCommand) as? Bool ?? ActivationHotKey.default.usesCommand
        let activationUsesOption = userDefaults.object(forKey: Keys.activationUsesOption) as? Bool ?? ActivationHotKey.default.usesOption
        let activationUsesControl = userDefaults.object(forKey: Keys.activationUsesControl) as? Bool ?? ActivationHotKey.default.usesControl
        let activationUsesShift = userDefaults.object(forKey: Keys.activationUsesShift) as? Bool ?? ActivationHotKey.default.usesShift
        let mode = GridLayoutMode(rawValue: userDefaults.string(forKey: Keys.layoutMode) ?? "") ?? .qwerty
        let customRowsText = userDefaults.string(forKey: Keys.customRows) ?? ""
        return StoredAppSettings(
            activationMode: activationMode,
            activationKeyText: activationKeyText,
            activationUsesCommand: activationUsesCommand,
            activationUsesOption: activationUsesOption,
            activationUsesControl: activationUsesControl,
            activationUsesShift: activationUsesShift,
            layoutMode: mode,
            customRowsText: customRowsText
        )
    }

    func save(_ settings: StoredAppSettings) {
        userDefaults.set(settings.activationMode.rawValue, forKey: Keys.activationMode)
        userDefaults.set(settings.activationKeyText, forKey: Keys.activationKey)
        userDefaults.set(settings.activationUsesCommand, forKey: Keys.activationUsesCommand)
        userDefaults.set(settings.activationUsesOption, forKey: Keys.activationUsesOption)
        userDefaults.set(settings.activationUsesControl, forKey: Keys.activationUsesControl)
        userDefaults.set(settings.activationUsesShift, forKey: Keys.activationUsesShift)
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
