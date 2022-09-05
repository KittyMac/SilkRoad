import XCTest
import SilkRoadFramework
import Hitch
import Flynn
import Picaroon

final class SilkRoadTests: XCTestCase {
    
    func testPublicSwiftFunc() {
        XCTAssertEqual(SilkRoadFramework.add(x: 40, y: 2), 42)
    }
    
    func testPublicJsonPath() {
        let json: Hitch = #"[0,1,2,3,4,5,6,7,8,9]"#
        let path: Hitch = #"$[3,6,-2]"#
        let resultsPtr = SilkRoadFramework.jsonpath(queryUTF8: path.raw(), jsonUTF8: json.raw())!
        let results = Hitch(utf8: resultsPtr)
        XCTAssertEqual(results, "[3,6,8]")
    }
    
    func testFlynnActors() {
        let expectation = XCTestExpectation(description: "wait for result")
        let lowercase = Lowercase()
        lowercase.beToLowercase(string: "HELLO WORLD", Flynn.any) { result in
            XCTAssertEqual(result, "hello world")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testDownload() {
        let expectation = XCTestExpectation(description: "wait for result")
        
        print("BEFORE REQUEST")
        Picaroon.urlRequest(url: "https://www.swift-linux.com/sextant/",
                            httpMethod: "GET",
                            params: [:],
                            headers: [:],
                            body: nil, Flynn.any) { data, httpResponse, error in
            
            print("data: \(data)")
            print("httpResponse: \(httpResponse)")
            print("error: \(error)")
            
            print("AFTER REQUEST")
            
            if let data = data {
                print(String(data: data, encoding: .utf8)!)
                expectation.fulfill()
                return
            }
            
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
