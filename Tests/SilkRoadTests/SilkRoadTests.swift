import XCTest
import SilkRoadFramework

final class SilkRoadTests: XCTestCase {
    func testSilkRoadHelloWorld() throws {
        //XCTAssertEqual(SilkRoad().text, "Hello, World!")
    }
    
    func testPublicSwiftFunc() throws {
        print(SilkRoadFramework.add(env: 0, this: 0, x: 0, y: 0))
        //helloWorld()
    }
}
