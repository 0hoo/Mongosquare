import XCTest
@testable import Schrodinger

class SchrodingerTests: XCTestCase {
    func testExample() {
        let now = Date()
        let string = async(hello)
        XCTAssertEqual(try string.await(), "world")
        XCTAssertGreaterThanOrEqual(Date(), now.addingTimeInterval(1))
    }

    func hello() -> String {
        sleep(1)
        return "world"
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
