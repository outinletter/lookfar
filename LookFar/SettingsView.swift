import SwiftUI
import UserNotifications

enum AppInformation {
    static let support = "outinaddvalue@gmail.com"
    static var privacy: String {
        L("LookFar 개인정보 처리방침\n시행일: 2026년 10월 15일\n\nLookFar는 계정, 광고, 분석 도구, 추적 SDK, 자체 서버를 사용하지 않으며 개인정보를 수집하거나 판매하지 않습니다. 카메라, 마이크, 위치, 연락처, 사진, 건강 데이터에 접근하지 않습니다. 스마트폰 사용 시간이나 실제 눈의 움직임도 감지하지 않습니다.\n\n알림 간격, 소리, 실시간 현황 설정, 진행 중인 타이머와 사용자가 완료한 휴식 기록은 이 기기의 앱 저장공간에 보관됩니다. 시스템 백업 설정에 따라 기기 백업에 포함될 수 있습니다.\n\n알림과 실시간 현황은 Apple의 시스템 기능을 이용해 기기에서 처리됩니다. 푸시 서버나 네트워크 요청은 사용하지 않습니다. 잠금 화면에 타이머가 표시될 수 있으며 iOS 설정에서 표시 여부를 바꿀 수 있습니다.\n\n설정의 ‘모든 데이터 초기화’로 타이머, 알림, 기록과 앱 설정을 삭제할 수 있습니다. 앱 삭제로도 로컬 데이터를 삭제할 수 있으며 기존 백업은 별도로 관리해 주세요.\n\n지원 이메일을 보내기로 선택한 경우 사용자가 보내는 이메일 주소와 문의 내용은 이메일 서비스 제공업체를 통해 개발자에게 전달됩니다. 민감한 정보는 보내지 마세요.\n\n개발자: ADDVALUE\n문의: \(support)",
          "LookFar Privacy Policy\nEffective October 15, 2026\n\nLookFar uses no account, advertising, analytics, tracking SDK, or developer-operated server. We do not collect or sell personal data. No camera, microphone, location, contacts, photos, or health data is accessed. The app does not monitor screen use or detect actual eye movements.\n\nReminder preferences, the active timer, and completed break history stay in this app's storage on your device. They may be included in device backups according to your system settings.\n\nLocal notifications and Live Activities use Apple's on-device system features. No push server or network requests are used. Timer information may appear on the Lock Screen; you control visibility in iOS Settings.\n\nUse Reset all data in Settings to delete timers, notifications, history, and preferences. Uninstalling also removes local app data. Existing backups are managed separately.\n\nIf you choose to email support, your email address and message pass through email providers to the developer. Please do not include sensitive information.\n\nDeveloper: ADDVALUE\nContact: \(support)")
    }
}

struct SettingsView: View {
    @Bindable var store: ReminderStore
    @State private var confirmReset = false
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image("BrandIcon").resizable().frame(width: 68, height: 68).clipShape(RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LookFar").font(.title2.weight(.semibold))
                        Text(L("시선에 작은 쉼표를.", "A little pause for your eyes.")).font(.caption).foregroundStyle(Palette.muted)
                        Text("1.0 (1)").font(.caption2).foregroundStyle(Palette.muted)
                    }
                }.padding(.vertical, 10)
            }.listRowBackground(Palette.card)
            Section {
                LabeledContent(L("알림 권한", "Permission"), value: store.notificationsAllowed ? L("허용됨", "Allowed") : L("허용 필요", "Not allowed"))
                Toggle(L("알림 소리", "Notification sound"), isOn: $store.sound).accessibilityIdentifier("soundToggle")
                Button(L("iOS 알림 설정 열기", "Open iOS notification settings")) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                if !store.bannersEnabled, store.notificationsAllowed {
                    Label(L("배너가 꺼져 있습니다. iOS 설정에서 배너를 켜주세요.", "Banners are off. Enable banners in iOS Settings."), systemImage: "exclamationmark.circle").font(.caption)
                }
            } header: { Text(L("알림", "NOTIFICATIONS")) } footer: {
                Text(L("소리 변경은 다음에 시작하는 타이머부터 적용됩니다. 무음 모드·집중 모드·알림 요약은 표시와 소리에 영향을 줄 수 있습니다.", "Sound changes apply to the next timer. Silent mode, Focus, and Scheduled Summary may affect alerts."))
            }.listRowBackground(Palette.card)
            Section {
                Toggle(L("잠금 화면 · Dynamic Island", "Lock Screen · Dynamic Island"), isOn: $store.showIsland).accessibilityIdentifier("islandToggle")
            } header: { Text(L("실시간 현황", "LIVE ACTIVITY")) } footer: {
                Text(L("다음 타이머부터 적용됩니다. 지원 기기에서 남은 시간을 표시합니다. 종료 시 알림은 별도의 배너로 전달됩니다. Dynamic Island 표시와 확장은 iOS가 결정합니다.", "Applies to the next timer. Shows a countdown on supported devices. The end reminder is a separate notification. iOS controls Dynamic Island visibility and expansion."))
            }.listRowBackground(Palette.card)
            Section(L("사용 안내", "HOW IT WORKS")) {
                Text(L("1. 1~180분 중 원하는 간격을 고르세요.\n2. 알림 시작을 누르고 평소처럼 기기를 사용하세요.\n3. LOOKFAR 알림이 오면 화면에서 눈을 떼어보세요.\n4. 20초 휴식을 완료하고 다음 알림을 시작하세요.", "1. Choose an interval from 1 to 180 minutes.\n2. Start your reminder and use your device normally.\n3. When LOOKFAR arrives, look away from the screen.\n4. Complete a 20-second break and start your next reminder."))
                    .font(.subheadline).lineSpacing(6)
                Text(L("시간은 시작 버튼을 누른 시점부터 계산합니다. 실제 스마트폰 사용 시간을 측정하지 않으며, 알림은 한 번씩 예약됩니다.", "Time runs from when you press Start. LookFar does not measure actual phone use. Each timer schedules one reminder."))
                    .font(.caption).foregroundStyle(Palette.muted)
            }.listRowBackground(Palette.card)
            Section {
                NavigationLink(L("개인정보 처리방침", "Privacy policy")) {
                    ScrollView { Text(AppInformation.privacy).font(.subheadline).lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading).padding(25) }
                        .background(Palette.background).navigationTitle(L("개인정보 처리방침", "Privacy policy"))
                }.accessibilityIdentifier("privacyPolicy")
                Link(L("개발자에게 문의", "Contact support"), destination: URL(string: "mailto:\(AppInformation.support)?subject=LookFar%20Support")!)
                Text(AppInformation.support).font(.caption).textSelection(.enabled)
                Button(L("모든 데이터 초기화", "Reset all data"), role: .destructive) { confirmReset = true }.accessibilityIdentifier("resetData")
            } header: { Text(L("개인정보 및 지원", "PRIVACY & SUPPORT")) } footer: {
                Text(L("일상 속 눈 휴식 습관을 위한 앱입니다. 의료 진단·치료·시력 개선을 보장하지 않습니다.", "For everyday eye-break habits. Does not diagnose, treat, or guarantee improved eyesight."))
            }.listRowBackground(Palette.card)
            Text("© 2026 ADDVALUE").font(.caption2).foregroundStyle(Palette.muted).frame(maxWidth: .infinity).listRowBackground(Color.clear)
        }.scrollContentBackground(.hidden).background(Palette.background).foregroundStyle(Palette.ivory)
            .navigationTitle(L("설정", "Settings")).navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(L("모든 데이터를 삭제할까요?", "Reset all data?"), isPresented: $confirmReset, titleVisibility: .visible) {
                Button(L("초기화", "Reset"), role: .destructive) { Task { await store.reset() } }
                Button(L("취소", "Cancel"), role: .cancel) {}
            } message: { Text(L("진행 중인 알림, 휴식 기록과 설정이 삭제됩니다.", "This removes your active reminder, break history, and preferences.")) }
    }
}
