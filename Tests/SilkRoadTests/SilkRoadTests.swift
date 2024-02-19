import XCTest
import SilkRoadFramework
import Hitch
import Flynn
import Picaroon
import MailPacket

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
        
        let url: Hitch = "https://www.swift-linux.com/sextant/"
        
        let result: CallbackPtr = { info, data in
            print("DONE!")
            //expectation.fulfill()
        }
        
        SilkRoadFramework.download(url: url.export().0, result, nil)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testOCR() {
        SilkRoadFramework.ocr()
    }
    
    func testIMAP() {
        let expectation = XCTestExpectation(description: #function)

        let imap = IMAP(domain: "imap.gmail.com",
                        port: 993)
        
        imap.beConnect(account: "test.rocco.receiptpal@gmail.com",
                       password: "qtxf ktfw wutc fntv",
                       imap) { error in
            
            XCTAssertNil(error)
            
            imap.beSearch(folder: "INBOX",
                          after: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30 * -1),
                          imap) { error in
                XCTAssertNil(error)
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
