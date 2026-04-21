#if os(macOS)
import Foundation
import arstdhneioCore

struct AppConfiguration {
    let gridLayout: GridLayout

    static func load(arguments: [String] = CommandLine.arguments, environment: [String: String] = ProcessInfo.processInfo.environment) -> AppConfiguration {
        let layoutArgument = argumentValue(named: "--grid-keymap", in: arguments) ?? environment["ARSTDHNEIO_GRID_KEYMAP"] ?? environment["ASDFGHJKL_GRID_KEYMAP"]
        let rowsArgument = argumentValue(named: "--grid-key-rows", in: arguments) ?? environment["ARSTDHNEIO_GRID_KEY_ROWS"] ?? environment["ASDFGHJKL_GRID_KEY_ROWS"]

        if let rowsArgument,
           let layout = GridLayout(rowStrings: rowsArgument.split(separator: ",").map(String.init)) {
            return AppConfiguration(gridLayout: layout)
        }

        if let layoutArgument,
           let preset = GridLayoutPreset(rawValue: layoutArgument.lowercased()) {
            return AppConfiguration(gridLayout: GridLayout(preset: preset))
        }

        return AppConfiguration(gridLayout: GridLayout())
    }

    private static func argumentValue(named name: String, in arguments: [String]) -> String? {
        if let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }

        let prefix = "\(name)="
        return arguments.first(where: { $0.hasPrefix(prefix) })?.dropFirst(prefix.count).description
    }
}
#endif
