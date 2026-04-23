import XCTest
@testable import OLEDYawnCore

final class DisplaySelectionTests: XCTestCase {
    private let displays = [
        DisplaySummary(index: 1, uuid: "00000000-0000-4000-8000-000000000001", productName: "AW3225QF"),
        DisplaySummary(index: 2, uuid: "00000000-0000-4000-8000-000000000002", productName: "DELL S2725QS"),
        DisplaySummary(index: 3, uuid: "00000000-0000-4000-8000-000000000003", productName: "DELL S3225QS"),
    ]

    func testResolvesByListIndex() {
        XCTAssertEqual(resolveDisplay("1", in: displays), .found(displays[0]))
    }

    func testResolvesByFullUUIDCaseInsensitively() {
        XCTAssertEqual(
            resolveDisplay("00000000-0000-4000-8000-000000000001", in: displays),
            .found(displays[0])
        )
    }

    func testResolvesByExactNameCaseInsensitively() {
        XCTAssertEqual(resolveDisplay("aw3225qf", in: displays), .found(displays[0]))
    }

    func testResolvesByUniqueSubstring() {
        XCTAssertEqual(resolveDisplay("S2725", in: displays), .found(displays[1]))
    }

    func testRejectsAmbiguousSubstring() {
        XCTAssertEqual(resolveDisplay("DELL", in: displays), .ambiguous("DELL", [displays[1], displays[2]]))
    }

    func testRejectsUnknownQuery() {
        XCTAssertEqual(resolveDisplay("Studio Display", in: displays), .notFound("Studio Display"))
    }
}
