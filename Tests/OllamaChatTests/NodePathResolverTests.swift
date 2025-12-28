import XCTest
@testable import OllamaChat

final class NodePathResolverTests: XCTestCase {
    func testResolvePathExpandsTilde() {
        let resolved = NodePathResolver.resolvePath("~/")

        let homePath = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let resolvedPath = resolved.map { URL(fileURLWithPath: $0).standardizedFileURL.path }

        XCTAssertEqual(resolvedPath, homePath)
    }

    func testResolvePathEmptyOrNil() {
        XCTAssertNil(NodePathResolver.resolvePath(nil))
        XCTAssertNil(NodePathResolver.resolvePath(""))
    }

    func testExistsDetectsFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString)
        let data = Data("test".utf8)
        try data.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        XCTAssertTrue(NodePathResolver.exists(fileURL.path))
    }
}
