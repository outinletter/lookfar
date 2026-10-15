import SwiftUI
import Observation
import UserNotifications
import ActivityKit

func L(_ ko: String, _ en: String) -> String {
    Locale.preferredLanguages.first?.hasPrefix("ko") == true ? ko : en
}

struct BreakRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let seconds: Int
}

@MainActor @Observable
final class ReminderStore {
    // Intents and the visible scene share one owner, including during background launches.
    static let shared = ReminderStore()
    var minutes: Int { didSet { UserDefaults.standard.set(minutes, forKey: "minutes") } }
    var sound: Bool { didSet { UserDefaults.standard.set(sound, forKey: "sound") } }
    var showIsland: Bool { didSet { UserDefaults.standard.set(showIsland, forKey: "showIsland") } }
    private(set) var deadline: Date?
    private(set) var startedAt: Date?
    private(set) var records: [BreakRecord]
    var permission: UNAuthorizationStatus = .notDetermined
    var bannersEnabled = true
    var scheduledCount = 0
    var error: String?
    var activityNotice: String?
    var isWorking = false
    var showingBreak = false
    var breakDeadline: Date?
    var breakStartedAt: Date?
    var breakFinished = false
    var selectedTab = 0
    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()
    static let notificationID = "lookfar.reminder"

    init() {
        let d = UserDefaults.standard
        minutes = min(180, max(1, d.object(forKey: "minutes") as? Int ?? 20))
        sound = d.object(forKey: "sound") as? Bool ?? true
        showIsland = d.object(forKey: "showIsland") as? Bool ?? true
        deadline = d.object(forKey: "deadline") as? Date
        startedAt = d.object(forKey: "startedAt") as? Date
        records = (d.data(forKey: "records").flatMap { try? JSONDecoder().decode([BreakRecord].self, from: $0) }) ?? []
        breakDeadline = d.object(forKey: "breakDeadline") as? Date
        breakStartedAt = d.object(forKey: "breakStartedAt") as? Date
        showingBreak = breakDeadline != nil
    }
    var running: Bool { deadline != nil }
    var today: [BreakRecord] { records.filter { Calendar.current.isDateInToday($0.date) } }
    var notificationsAllowed: Bool { permission == .authorized || permission == .provisional || permission == .ephemeral }

    func refresh() async {
        let settings = await center.notificationSettings()
        permission = settings.authorizationStatus
        bannersEnabled = settings.alertSetting == .enabled
        scheduledCount = await center.pendingNotificationRequests().filter { $0.identifier == Self.notificationID }.count
        if deadline == nil {
            await endActivities()
        }
        await handleNotificationRoute()
        checkTime()
    }
    func start(seconds override: TimeInterval? = nil, requestPermission: Bool = true) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        error = nil
        do {
            if requestPermission, await center.notificationSettings().authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            }
            let settings = await center.notificationSettings()
            permission = settings.authorizationStatus
            bannersEnabled = settings.alertSetting == .enabled
            guard notificationsAllowed else {
                error = L("알림이 꺼져 있습니다. 설정에서 LookFar 알림을 허용한 후 다시 시작해 주세요.", "Notifications are off. Allow LookFar notifications in Settings, then start again.")
                return
            }
            var duration = override ?? Double(minutes * 60)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-UITestShortTimer"), override == nil { duration = 4 }
            #endif
            let start = Date()
            let end = start.addingTimeInterval(max(1, duration))
            let content = UNMutableNotificationContent()
            content.title = "LOOKFAR"
            content.subtitle = L("잠깐, 시선을 멀리.", "A little distance. A little rest.")
            content.body = L("화면에서 눈을 떼고 먼 곳을 바라보세요. 천천히 눈도 깜빡여 주세요.", "Look away from your screen, focus on something far away, and blink gently.")
            content.categoryIdentifier = "LOOKFAR"
            if sound { content.sound = .default }
            let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, duration), repeats: false))
            try await center.add(request)
            deadline = end
            startedAt = start
            defaults.set(end, forKey: "deadline")
            defaults.set(start, forKey: "startedAt")
            scheduledCount = 1
            showingBreak = false
            await startActivity(start: start, end: end)
        } catch {
            self.error = L("알림을 예약하지 못했습니다. 다시 시도해 주세요. ", "Could not schedule your reminder. Please try again. ") + error.localizedDescription
        }
    }
    func startFromAutomation(restart: Bool = false) async throws {
        guard !isWorking else { throw AutomationFailure.busy }
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
            throw AutomationFailure.permission
        }
        if let end = breakDeadline, end <= Date(), !breakFinished { finishBreak() }
        guard breakDeadline == nil || breakFinished else { throw AutomationFailure.resting }
        // Opening another selected app must not keep pushing an active reminder into the future.
        if !restart, let deadline, deadline > Date() {
            let requests = await center.pendingNotificationRequests()
            if requests.contains(where: { $0.identifier == Self.notificationID }) { return }
        }
        // Scheduling can fail; retain the old timer until its replacement is successfully added.
        guard !isWorking else { throw AutomationFailure.busy }
        await start(requestPermission: false)
        if let error { throw AutomationFailure.scheduling(error) }
        clearBreak()
    }
    func stop() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.notificationID])
        deadline = nil
        startedAt = nil
        scheduledCount = 0
        defaults.removeObject(forKey: "deadline")
        defaults.removeObject(forKey: "startedAt")
        await endActivities()
    }
    func checkTime() {
        if let end = deadline, Date() >= end, !showingBreak { showingBreak = true }
        if let end = breakDeadline, Date() >= end, !breakFinished { finishBreak() }
    }
    func handleNotificationRoute() async {
        guard let action = defaults.string(forKey: "notificationRoute") else { return }
        defaults.removeObject(forKey: "notificationRoute")
        selectedTab = 0
        if action == "snooze" {
            clearBreak()
            await start(seconds: 300)
        } else {
            showingBreak = true
        }
    }
    func beginBreak() async {
        guard breakDeadline == nil else { return }
        await stop()
        let now = Date()
        breakStartedAt = now
        breakDeadline = now.addingTimeInterval(20)
        defaults.set(now, forKey: "breakStartedAt")
        defaults.set(breakDeadline, forKey: "breakDeadline")
        breakFinished = false
    }
    func finishBreak() {
        guard let end = breakDeadline, Date() >= end, !breakFinished else { return }
        // Count only a user-started rest, never an elapsed reminder or notification delivery.
        records.insert(BreakRecord(id: UUID(), date: end, seconds: 20), at: 0)
        records = Array(records.prefix(1000))
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: "records") }
        breakFinished = true
        defaults.removeObject(forKey: "breakDeadline")
        defaults.removeObject(forKey: "breakStartedAt")
    }
    func clearBreak() {
        breakDeadline = nil
        breakStartedAt = nil
        breakFinished = false
        showingBreak = false
        defaults.removeObject(forKey: "breakDeadline")
        defaults.removeObject(forKey: "breakStartedAt")
    }
    func closeBreak() async {
        if let end = deadline, Date() >= end { await stop() }
        clearBreak()
    }
    func snooze() async {
        clearBreak()
        await start(seconds: 300)
    }
    func reset() async {
        await stop()
        clearBreak()
        records = []
        defaults.removeObject(forKey: "records")
        defaults.removeObject(forKey: "notificationRoute")
        minutes = 20
        sound = true
        showIsland = true
        error = nil
        activityNotice = nil
    }
    private func startActivity(start: Date, end: Date) async {
        await endActivities()
        activityNotice = nil
        guard showIsland else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            activityNotice = L("실시간 현황이 꺼져 있습니다. 예약한 배너 알림은 계속 작동합니다.", "Live Activities are off. Your scheduled banner reminder is still active.")
            return
        }
        do {
            _ = try Activity<LookFarActivity>.request(
                attributes: LookFarActivity(title: L("다음 눈 휴식", "Next eye break")),
                content: ActivityContent(state: .init(start: start, deadline: end), staleDate: end), pushType: nil)
        } catch {
            activityNotice = L("실시간 현황을 표시하지 못했습니다. 예약한 배너 알림은 계속 작동합니다.", "Live Activity could not start. Your scheduled banner reminder is still active.")
        }
    }
    private func endActivities() async {
        for activity in Activity<LookFarActivity>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
