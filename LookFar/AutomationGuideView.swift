import SwiftUI

struct AutomationGuideView: View {
    var body: some View {
        Form {
            Section {
                Label(L("다른 앱을 열면, 눈 휴식 준비도 자동으로.", "Open an app. Start an eye-break reminder."), systemImage: "bolt.circle")
                    .font(.headline)
                Text(L("자동화는 사용자가 Apple 단축어 앱에서 한 번 설정해야 합니다. LookFar가 대신 생성하거나 사용 앱 목록을 읽지는 않습니다.", "Set up the automation once in Apple's Shortcuts app. LookFar cannot create it for you or read which apps you select."))
            }
            Section(L("설정 순서", "SETUP")) {
                step("1", L("LookFar에서 간격 설정", "Choose your interval in LookFar"), L("타이머 탭에서 시간을 정하고 알림을 한 번 시작해 알림 권한을 허용하세요. 자동화는 이 간격을 사용합니다.", "Choose a duration on Timer and start once to allow notifications. Automations use this saved duration."))
                step("2", L("단축어 → 자동화 → +", "Shortcuts → Automation → +"), L("‘앱’을 선택하고 Instagram, YouTube 등 원하는 앱을 고르세요. ‘열릴 때’와 ‘즉시 실행’을 선택하세요. iOS 버전에 따라 ‘실행 전에 묻기’를 끄는 방식일 수 있습니다.", "Choose App, then select apps such as Instagram or YouTube. Select Is Opened and Run Immediately. On some iOS versions, turn off Ask Before Running instead."))
                step("3", L("LookFar 동작 추가", "Add a LookFar action"), L("새로운 빈 자동화에서 LookFar를 검색하고 ‘눈 휴식 타이머 시작’을 추가해 저장하세요. ‘앱 열기’ 동작이 아니라 LookFar의 타이머 동작을 선택하세요.", "In a new blank automation, search LookFar and add Start eye-break timer, then save. Use the LookFar timer action, not Open App."))
                step("4", L("선택한 앱을 열어 확인", "Open a selected app to test"), L("LookFar 화면으로 이동하지 않고 타이머가 시작됩니다. 알림 시간이 되면 다른 앱을 사용하는 중에도 LOOKFAR 알림이 도착합니다.", "The timer starts without switching to LookFar. A LOOKFAR notification arrives when it ends, even while using another app."))
                Link(L("단축어 앱 열기", "Open Shortcuts"), destination: URL(string: "shortcuts://")!)
                    .accessibilityIdentifier("openShortcuts")
            }
            Section(L("앱 전환 시 동작", "WHEN SWITCHING APPS")) {
                Text(L("‘눈 휴식 타이머 시작’은 진행 중인 타이머를 유지합니다. 여러 앱을 오갈 때 알림 시간이 계속 미뤄지지 않습니다.", "Start eye-break timer keeps an active timer running, so switching apps does not keep postponing your reminder."))
                Text(L("선택한 앱을 열 때마다 전체 시간으로 초기화하려면 대신 ‘눈 휴식 타이머 새로 시작’을 선택하세요. ‘눈 휴식 타이머 종료’ 동작으로 예약을 취소할 수도 있습니다.", "To reset to the full duration every time a selected app opens, use Restart eye-break timer instead. End eye-break timer cancels the reminder."))
            }
            Section(L("꼭 알아두세요", "IMPORTANT")) {
                Text(L("이 기능은 ‘선택한 앱 열기’ 기준이며 화면 켜짐이나 잠금 해제를 감지하지 않습니다. 화면을 꺼도 타이머는 계속되고, 다시 켜는 것만으로 초기화되지 않습니다. 선택한 앱을 이미 연 상태에서 잠금만 해제하면 자동화가 다시 실행되지 않을 수 있습니다.", "This triggers on opening selected apps, not waking or unlocking the screen. The timer continues while the screen is off and does not reset just by waking it. Unlocking into an already-open selected app may not trigger the automation again."))
                    .accessibilityIdentifier("automationLimitations")
                Text(L("실제 화면 사용 시간이나 시선을 측정하지 않습니다. 타이머는 한 번씩 실행되며 20초 휴식 중에는 자동 시작을 거절합니다. 집중 모드와 알림 설정에 따라 표시가 달라집니다.", "This does not measure actual screen time or gaze. Each timer is one-shot; auto-start is rejected during a 20-second break. Focus and notification settings affect delivery."))
            }
        }
        .font(.subheadline).scrollContentBackground(.hidden)
        .background(Palette.background).foregroundStyle(Palette.ivory)
        .navigationTitle(L("앱 실행 시 자동 시작", "Start when apps open"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(number). \(title)").font(.headline)
            Text(detail).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 5)
    }
}
