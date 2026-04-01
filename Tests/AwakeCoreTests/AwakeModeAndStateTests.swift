import XCTest
@testable import AwakeCore

final class AwakeModeAndStateTests: XCTestCase {
    func testAwakeModeHelpers() {
        let timed = AwakeMode.timed(duration: 42)
        XCTAssertTrue(timed.isTimed)
        XCTAssertEqual(timed.duration, 42)

        let indefinite = AwakeMode.indefinite
        XCTAssertFalse(indefinite.isTimed)
        XCTAssertNil(indefinite.duration)
    }

    func testAwakeStateHelpers() {
        let now = Date(timeIntervalSince1970: 100)
        let active = AwakeState.active(mode: .timed(duration: 10), startedAt: now, endsAt: now.addingTimeInterval(10))

        XCTAssertTrue(active.isActive)
        XCTAssertEqual(active.endsAt, now.addingTimeInterval(10))
        XCTAssertFalse(AwakeState.inactive.isActive)
        XCTAssertNil(AwakeState.inactive.endsAt)
    }
}
