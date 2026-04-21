#if os(macOS)
import XCTest
@testable import arstdhneio

final class AppBundleSupportTests: XCTestCase {
    func testBundledAppDetectionRecognizesAppExtension() {
        let bundleURL = URL(fileURLWithPath: "/Applications/arstdhneio.app")

        XCTAssertTrue(AppBundleSupport.isBundledApp(bundleURL: bundleURL))
    }

    func testBundledAppDetectionRejectsRawExecutablePath() {
        let bundleURL = URL(fileURLWithPath: "/tmp/arstdhneio")

        XCTAssertFalse(AppBundleSupport.isBundledApp(bundleURL: bundleURL))
    }

    func testInfoPlistContainsMenuBarBundleMetadata() {
        let plist = AppBundleSupport.infoPlist(version: "1.2.3", build: "42")

        XCTAssertEqual(plist["CFBundleName"] as? String, "arstdhneio")
        XCTAssertEqual(plist["CFBundleIdentifier"] as? String, "com.levyatsishin.arstdhneio")
        XCTAssertEqual(plist["CFBundleExecutable"] as? String, "arstdhneio")
        XCTAssertEqual(plist["CFBundleShortVersionString"] as? String, "1.2.3")
        XCTAssertEqual(plist["CFBundleVersion"] as? String, "42")
        XCTAssertEqual(plist["LSUIElement"] as? Bool, true)
    }
}
#endif
