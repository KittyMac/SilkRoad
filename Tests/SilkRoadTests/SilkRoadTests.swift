import XCTest
import SilkRoadFramework
import Hitch

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
}
