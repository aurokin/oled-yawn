import XCTest
@testable import OLEDYawnCore

final class HelpTextTests: XCTestCase {
    func testQuickHelpMentionsDryRunAndDoctor() {
        let text = helpText(program: "oled-yawn")

        XCTAssertTrue(text.contains("sleep 1 --dry-run"))
        XCTAssertTrue(text.contains("doctor"))
    }

    func testDoctorHelpIsProgressivelyDiscoverable() {
        let text = helpText(program: "oled-yawn", topic: "doctor")

        XCTAssertTrue(text.contains("oled-yawn doctor <display>"))
        XCTAssertTrue(text.contains("does not write DDC commands"))
    }

    func testSleepHelpMentionsDryRun() {
        let text = helpText(program: "oled-yawn", topic: "sleep")

        XCTAssertTrue(text.contains("--dry-run"))
        XCTAssertTrue(text.contains("without sending a DDC write"))
    }
}
