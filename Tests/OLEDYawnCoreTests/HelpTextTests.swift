import XCTest
@testable import OLEDYawnCore

final class HelpTextTests: XCTestCase {
    func testQuickHelpMentionsPowerCommandsAndYes() {
        let text = helpText(program: "oled-yawn")

        XCTAssertTrue(text.contains("sleep 1 --yes"))
        XCTAssertTrue(text.contains("wake 1 --yes"))
        XCTAssertTrue(text.contains("toggle 1"))
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

        XCTAssertTrue(text.contains("--yes"))
        XCTAssertTrue(text.contains("--dry-run"))
        XCTAssertTrue(text.contains("without sending a DDC write"))
    }

    func testWakeHelpMentionsDDCLimitations() {
        let text = helpText(program: "oled-yawn", topic: "wake")

        XCTAssertTrue(text.contains("wake [display]"))
        XCTAssertTrue(text.contains("VCP 0xD6"))
        XCTAssertTrue(text.contains("stop accepting DDC commands"))
    }

    func testToggleHelpMentionsReadFailureBehavior() {
        let text = helpText(program: "oled-yawn", topic: "toggle")

        XCTAssertTrue(text.contains("toggle [display]"))
        XCTAssertTrue(text.contains("reads VCP 0xD6"))
        XCTAssertTrue(text.contains("exits without"))
    }
}
