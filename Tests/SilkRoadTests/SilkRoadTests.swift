import XCTest
@testable import SilkRoadFramework

final class SilkRoadTests: XCTestCase {
    func testSilkRoadHelloWorld() throws {
        XCTAssertEqual(SilkRoad().text, "Hello, World!")
    }
    
    func testPublicSwiftFunc() throws {
        XCTAssertEqual(helloWorld(), "Hello, World!")
    }
}