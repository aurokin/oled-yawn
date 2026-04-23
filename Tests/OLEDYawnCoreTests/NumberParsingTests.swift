import XCTest
@testable import OLEDYawnCore

final class NumberParsingTests: XCTestCase {
    func testParsesDecimalAndHex() {
        XCTAssertEqual(parseUnsignedInteger("214"), 214)
        XCTAssertEqual(parseUnsignedInteger("0xD6"), 214)
        XCTAssertEqual(parseUnsignedInteger("0Xd6"), 214)
    }

    func testRejectsNegativeAndEmptyValues() {
        XCTAssertNil(parseUnsignedInteger("-1"))
        XCTAssertNil(parseUnsignedInteger(""))
        XCTAssertNil(parseUnsignedInteger("   "))
    }

    func testValidatesUInt8Range() {
        XCTAssertEqual(parseUInt8Value("0xFF"), 255)
        XCTAssertNil(parseUInt8Value("256"))
    }

    func testValidatesUInt16Range() {
        XCTAssertEqual(parseUInt16Value("65535"), 65_535)
        XCTAssertNil(parseUInt16Value("65536"))
    }
}
