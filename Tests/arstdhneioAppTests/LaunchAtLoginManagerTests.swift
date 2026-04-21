#if os(macOS)
import XCTest
@testable import arstdhneio

final class LaunchAtLoginManagerTests: XCTestCase {
    func testUnavailableWhenNotRunningFromBundledApp() {
        let manager = LaunchAtLoginManager(
            service: StubLaunchAtLoginService(status: .notRegistered),
            isBundledAppProvider: { false }
        )

        XCTAssertEqual(manager.status, .unavailable)
        XCTAssertFalse(manager.isAvailable)
    }

    func testToggleRegistersWhenDisabled() throws {
        let service = StubLaunchAtLoginService(status: .notRegistered)
        let manager = LaunchAtLoginManager(
            service: service,
            isBundledAppProvider: { true }
        )

        let updatedStatus = try manager.toggle()

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertEqual(service.unregisterCallCount, 0)
        XCTAssertEqual(updatedStatus, .enabled)
    }

    func testToggleUnregistersWhenEnabled() throws {
        let service = StubLaunchAtLoginService(status: .enabled)
        let manager = LaunchAtLoginManager(
            service: service,
            isBundledAppProvider: { true }
        )

        let updatedStatus = try manager.toggle()

        XCTAssertEqual(service.registerCallCount, 0)
        XCTAssertEqual(service.unregisterCallCount, 1)
        XCTAssertEqual(updatedStatus, .notRegistered)
    }

    func testToggleOpensSystemSettingsWhenApprovalIsRequired() throws {
        let service = StubLaunchAtLoginService(status: .requiresApproval)
        let manager = LaunchAtLoginManager(
            service: service,
            isBundledAppProvider: { true }
        )

        let updatedStatus = try manager.toggle()

        XCTAssertEqual(service.openSettingsCallCount, 1)
        XCTAssertEqual(updatedStatus, .requiresApproval)
    }

    func testToggleThrowsOutsideAppBundle() {
        let manager = LaunchAtLoginManager(
            service: StubLaunchAtLoginService(status: .notRegistered),
            isBundledAppProvider: { false }
        )

        XCTAssertThrowsError(try manager.toggle()) { error in
            XCTAssertEqual(error as? LaunchAtLoginError, .requiresBundledApp)
        }
    }
}

private final class StubLaunchAtLoginService: LaunchAtLoginServicing {
    private(set) var status: LaunchAtLoginStatus
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    private(set) var openSettingsCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        status = .notRegistered
    }

    func openSystemSettings() {
        openSettingsCallCount += 1
    }
}
#endif
