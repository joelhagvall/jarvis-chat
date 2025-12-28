import XCTest
@testable import OllamaChat

// MARK: - Mock Process Launcher

final class MockProcessLauncher: ProcessLaunching, @unchecked Sendable {
    private let lock = NSLock()
    private var _launchCount = 0
    private var _shouldFail = false

    var launchCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _launchCount
    }

    var shouldFail: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shouldFail
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shouldFail = newValue
        }
    }

    func launchOllamaServe() throws {
        lock.lock()
        _launchCount += 1
        let fail = _shouldFail
        lock.unlock()

        if fail {
            throw NSError(domain: "MockProcessLauncher", code: 1, userInfo: nil)
        }
    }
}

// MARK: - Mock Health Checker

actor MockHealthChecker: HealthChecking {
    var isHealthy = false
    private(set) var checkCount = 0

    func setHealthy(_ value: Bool) {
        isHealthy = value
    }

    func checkOllamaHealth() async -> Bool {
        checkCount += 1
        return isHealthy
    }

    func getCheckCount() -> Int {
        checkCount
    }
}

// MARK: - Tests

final class OllamaServiceTests: XCTestCase {

    // MARK: - ensureRunning Tests

    func testEnsureRunningDoesNotStartWhenAlreadyRunning() async throws {
        let mockLauncher = MockProcessLauncher()
        let mockHealthChecker = MockHealthChecker()
        await mockHealthChecker.setHealthy(true)

        let service = OllamaService(processLauncher: mockLauncher, healthChecker: mockHealthChecker)

        try await service.ensureRunning()

        XCTAssertEqual(mockLauncher.launchCount, 0, "Should not launch when already running")
        let checkCount = await mockHealthChecker.getCheckCount()
        XCTAssertEqual(checkCount, 1, "Should check health once")
    }

    func testEnsureRunningStartsWhenNotRunning() async throws {
        let mockLauncher = MockProcessLauncher()
        let mockHealthChecker = MockHealthChecker()
        await mockHealthChecker.setHealthy(false)

        let service = OllamaService(processLauncher: mockLauncher, healthChecker: mockHealthChecker)

        // After launching, simulate Ollama becoming healthy
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await mockHealthChecker.setHealthy(true)
        }

        try await service.ensureRunning()

        XCTAssertEqual(mockLauncher.launchCount, 1, "Should launch once")
        let checkCount = await mockHealthChecker.getCheckCount()
        XCTAssertGreaterThan(checkCount, 1, "Should check health multiple times while waiting")
    }

    func testEnsureRunningThrowsWhenStartFails() async {
        let mockLauncher = MockProcessLauncher()
        mockLauncher.shouldFail = true
        let mockHealthChecker = MockHealthChecker()
        await mockHealthChecker.setHealthy(false)

        let service = OllamaService(processLauncher: mockLauncher, healthChecker: mockHealthChecker)

        do {
            try await service.ensureRunning()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is OllamaError)
            if case OllamaError.failedToStart = error {
                // Expected
            } else {
                XCTFail("Expected failedToStart error")
            }
        }
    }

    func testEnsureRunningThrowsWhenOllamaDoesNotBecomeHealthy() async {
        let mockLauncher = MockProcessLauncher()
        let mockHealthChecker = MockHealthChecker()
        await mockHealthChecker.setHealthy(false)

        let service = OllamaService(processLauncher: mockLauncher, healthChecker: mockHealthChecker)

        do {
            try await service.ensureRunning()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is OllamaError)
            if case OllamaError.failedToStart = error {
                // Expected - Ollama never became healthy after 10 seconds
            } else {
                XCTFail("Expected failedToStart error")
            }
        }

        XCTAssertEqual(mockLauncher.launchCount, 1, "Should have tried to launch")
        let checkCount = await mockHealthChecker.getCheckCount()
        XCTAssertEqual(checkCount, 21, "Should check health 1 initial + 20 retries")
    }

    // MARK: - Process Launcher Tests

    func testSystemProcessLauncherCreatesCorrectProcess() {
        // This is more of a smoke test - we can't easily verify the process details
        // without actually running it, which would affect the system
        let launcher = SystemProcessLauncher()
        XCTAssertNotNil(launcher)
    }

    // MARK: - Health Checker Tests

    func testHTTPHealthCheckerInitialization() {
        let checker = HTTPHealthChecker()
        XCTAssertNotNil(checker)
    }

    func testHTTPHealthCheckerWithCustomURL() {
        let checker = HTTPHealthChecker(baseURL: "http://localhost:9999")
        XCTAssertNotNil(checker)
    }
}
