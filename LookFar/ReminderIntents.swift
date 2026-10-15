import AppIntents

enum AutomationFailure: LocalizedError {
    case permission, busy, resting, scheduling(String)
    var errorDescription: String? {
        switch self {
        case .permission:
            return L("LookFar를 열어 알림을 허용하고 타이머를 한 번 시작한 뒤 다시 실행해 주세요.", "Open LookFar, allow notifications, and start a timer once before running this action.")
        case .busy:
            return L("타이머를 처리 중입니다. 잠시 후 다시 실행해 주세요.", "A timer operation is in progress. Try again shortly.")
        case .resting:
            return L("20초 휴식이 진행 중입니다. LookFar에서 휴식을 마친 뒤 다시 실행해 주세요.", "A 20-second break is in progress. Finish it in LookFar before starting a timer.")
        case .scheduling(let message): return message
        }
    }
}

// LiveActivityIntent executes in the app process without bringing LookFar in front
// of the selected app, and permits starting the optional countdown activity.
struct StartReminderIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "눈 휴식 타이머 시작"
    static let description = IntentDescription("설정한 간격으로 시작합니다. 진행 중인 타이머는 유지합니다.")
    static let openAppWhenRun = false

    @MainActor func perform() async throws -> some IntentResult {
        try await ReminderStore.shared.startFromAutomation()
        return .result()
    }
}

struct RestartReminderIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "눈 휴식 타이머 새로 시작"
    static let description = IntentDescription("기존 타이머를 설정한 시간 전체로 초기화합니다.")
    static let openAppWhenRun = false

    @MainActor func perform() async throws -> some IntentResult {
        try await ReminderStore.shared.startFromAutomation(restart: true)
        return .result()
    }
}

struct StopReminderIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "눈 휴식 타이머 종료"
    static let description = IntentDescription("예정 알림과 실시간 현황을 취소합니다.")
    static let openAppWhenRun = false

    @MainActor func perform() async throws -> some IntentResult {
        guard !ReminderStore.shared.isWorking else { throw AutomationFailure.busy }
        await ReminderStore.shared.stop()
        return .result()
    }
}

struct LookFarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartReminderIntent(), phrases: ["\(.applicationName) 타이머 시작"], shortTitle: "타이머 시작", systemImageName: "play.circle")
        AppShortcut(intent: RestartReminderIntent(), phrases: ["\(.applicationName) 타이머 새로 시작"], shortTitle: "타이머 새로 시작", systemImageName: "arrow.clockwise")
        AppShortcut(intent: StopReminderIntent(), phrases: ["\(.applicationName) 타이머 종료"], shortTitle: "타이머 종료", systemImageName: "stop.circle")
    }
}
