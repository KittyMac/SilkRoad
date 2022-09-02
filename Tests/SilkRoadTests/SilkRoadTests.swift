import XCTest
import SilkRoadFramework
import Hitch
import Flynn

final class SilkRoadTests: XCTestCase {
    func testSilkRoadHelloWorld() throws {
        //XCTAssertEqual(SilkRoad().text, "Hello, World!")
    }
    
    func testPublicSwiftFunc() throws {
        XCTAssertEqual(SilkRoadFramework.add(x: 40, y: 2), 42)
    }
    
    func testPublicJsonPath() throws {
        let json: Hitch = #"[0,1,2,3,4,5,6,7,8,9]"#
        let path: Hitch = #"$[3,6,-2]"#
        let resultsPtr = SilkRoadFramework.jsonpath(queryUTF8: path.raw(), jsonUTF8: json.raw())!
        let results = Hitch(utf8: resultsPtr)
        XCTAssertEqual(results, "[3,6,8]")
    }
    
    func testFlynnActors() throws {
        let expectation = XCTestExpectation(description: "wait for result")
        let lowercase = Lowercase()
        lowercase.beToLowercase(string: "HELLO WORLD", Flynn.any) { result in
            XCTAssertEqual(result, "hello world")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
