import XCTest
import UserNotifications
@testable import LookFar

@MainActor
final class ReminderIntentTests: XCTestCase {
    private var savedMinutes = 20
    private var savedSound = true
    private var savedIsland = true
    private var store: ReminderStore { .shared }

    override func setUp() async throws {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        try XCTSkipUnless([.authorized, .provisional, .ephemeral].contains(status), "Allow notifications in LookFar before device tests.")
        savedMinutes = store.minutes
        savedSound = store.sound
        savedIsland = store.showIsland
        await store.stop()
        store.clearBreak()
        store.minutes = 20
        store.sound = false
        store.showIsland = false
    }

    override func tearDown() async throws {
        await store.stop()
        store.clearBreak()
        store.minutes = savedMinutes
        store.sound = savedSound
        store.showIsland = savedIsland
    }

    func testStartUsesSavedIntervalAndKeepsExistingTimer() async throws {
        store.minutes = 10
        _ = try await StartReminderIntent().perform()
        let first = try XCTUnwrap(store.deadline)
        XCTAssertEqual(first.timeIntervalSinceNow, 600, accuracy: 3)
        store.minutes = 30
        _ = try await StartReminderIntent().perform()
        XCTAssertEqual(store.deadline, first)
        XCTAssertEqual(ReminderStore().deadline, first)
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertEqual(pending.filter { $0.identifier == ReminderStore.notificationID }.count, 1)
    }

    func testRestartReplacesTimerWithFullSavedInterval() async throws {
        _ = try await StartReminderIntent().perform()
        let first = try XCTUnwrap(store.deadline)
        store.minutes = 30
        _ = try await RestartReminderIntent().perform()
        let next = try XCTUnwrap(store.deadline)
        XCTAssertGreaterThan(next, first)
        XCTAssertEqual(next.timeIntervalSinceNow, 1800, accuracy: 3)
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertEqual(pending.filter { $0.identifier == ReminderStore.notificationID }.count, 1)
    }

    func testStopRemovesPersistedTimerAndNotification() async throws {
        _ = try await StartReminderIntent().perform()
        _ = try await StopReminderIntent().perform()
        XCTAssertNil(store.deadline)
        XCTAssertNil(ReminderStore().deadline)
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertFalse(pending.contains { $0.identifier == ReminderStore.notificationID })
    }

    func testAutomationDoesNotInterruptRest() async throws {
        await store.beginBreak()
        do {
            _ = try await StartReminderIntent().perform()
            XCTFail("An in-progress break must not be interrupted")
        } catch AutomationFailure.resting { }
        XCTAssertNotNil(store.breakDeadline)
        XCTAssertNil(store.deadline)
    }

    func testMissingPendingRequestIsRepaired() async throws {
        _ = try await StartReminderIntent().perform()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [ReminderStore.notificationID])
        _ = try await StartReminderIntent().perform()
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertEqual(pending.filter { $0.identifier == ReminderStore.notificationID }.count, 1)
    }
}
