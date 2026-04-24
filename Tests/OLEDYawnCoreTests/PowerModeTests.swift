import XCTest
@testable import OLEDYawnCore

final class PowerModeTests: XCTestCase {
    func testToggleSleepsWhenCurrentModeIsOn() {
        XCTAssertEqual(toggledPowerAction(currentValue: 1), .sleep)
    }

    func testToggleWakesWhenCurrentModeIsNotOn() {
        XCTAssertEqual(toggledPowerAction(currentValue: 2), .wake)
        XCTAssertEqual(toggledPowerAction(currentValue: 3), .wake)
        XCTAssertEqual(toggledPowerAction(currentValue: 4), .wake)
    }

    func testDescribesKnownPowerModes() {
        XCTAssertEqual(describePowerMode(1), "on")
        XCTAssertEqual(describePowerMode(4), "sleep")
        XCTAssertEqual(describePowerMode(0x1234), "0x1234")
    }
}
