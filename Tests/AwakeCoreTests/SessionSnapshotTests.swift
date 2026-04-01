import XCTest
@testable import AwakeCore

final class SessionSnapshotTests: XCTestCase {
    func testSnapshotFromInactiveIsNil() {
        XCTAssertNil(SessionSnapshot.from(state: .inactive))
    }

    func testSnapshotFromTimedStateContainsEndDate() {
        let startedAt = Date(timeIntervalSince1970: 100)
        let endsAt = Date(timeIntervalSince1970: 160)
        let snapshot = SessionSnapshot.from(state: .active(mode: .timed(duration: 60), startedAt: startedAt, endsAt: endsAt))

        XCTAssertEqual(snapshot?.mode, .timed)
        XCTAssertEqual(snapshot?.startedAt, startedAt)
        XCTAssertEqual(snapshot?.endsAt, endsAt)
    }

    func testSnapshotFromIndefiniteStateHasNoEndDate() {
        let startedAt = Date(timeIntervalSince1970: 100)
        let snapshot = SessionSnapshot.from(state: .active(mode: .indefinite, startedAt: startedAt, endsAt: nil))

        XCTAssertEqual(snapshot?.mode, .indefinite)
        XCTAssertEqual(snapshot?.startedAt, startedAt)
        XCTAssertNil(snapshot?.endsAt)
    }
}
