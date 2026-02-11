import XCTest
@testable import LEANPlugin

class LEANTests: XCTestCase {
    func testPluginLoads() {
        // Plugin loads and exposes Lean bridge name
        let plugin = LEANPlugin()
        XCTAssertEqual(plugin.jsName, "Lean")
        XCTAssertEqual(plugin.identifier, "Lean")
    }
}
