#if os(macOS)
import Foundation

enum AppBundleSupport {
    static let bundleName = "arstdhneio"
    static let executableName = "arstdhneio"
    static let bundleIdentifier = "com.levyatsishin.arstdhneio"
    static let minimumSystemVersion = "13.0"
    static let defaultVersion = "0.1.0"
    static let defaultBuild = "1"

    static func isBundledApp(bundleURL: URL = Bundle.main.bundleURL) -> Bool {
        bundleURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame
    }

    static func infoPlist(version: String = defaultVersion, build: String = defaultBuild) -> [String: Any] {
        [
            "CFBundleName": bundleName,
            "CFBundleDisplayName": bundleName,
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleExecutable": executableName,
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": version,
            "CFBundleVersion": build,
            "LSMinimumSystemVersion": minimumSystemVersion,
            "LSUIElement": true,
            "NSHighResolutionCapable": true
        ]
    }
}
#endif
