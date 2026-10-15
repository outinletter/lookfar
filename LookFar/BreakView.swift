import SwiftUI

struct BreakView: View {
    @Bindable var store: ReminderStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                HStack {
                    Text("LOOKFAR").font(.caption.weight(.bold)).tracking(4).foregroundStyle(Palette.coral)
                    Spacer()
                    Button { Task { await store.closeBreak() } } label: { Image(systemName: "xmark").padding(12).background(Palette.card, in: Circle()) }
                        .accessibilityLabel(L("휴식 닫기", "Close break")).accessibilityIdentifier("closeBreak")
                }.padding(.top, 15)
                Text(store.breakFinished ? L("눈에도,\n여유가 생겼어요.", "A fresh view.\nA softer focus.") : L("화면은 잠시 내려놓고,\n먼 곳을 바라봐요.", "Set your screen aside.\nLook a little further."))
                    .font(.system(size: 32, weight: .semibold)).multilineTextAlignment(.center).tracking(-1).fixedSize(horizontal: false, vertical: true)
                ZStack {
                    Circle().stroke(Palette.sage.opacity(0.12), lineWidth: 1).frame(width: 266, height: 266)
                    Circle().fill(Palette.sage.opacity(0.08)).frame(width: 220, height: 220).scaleEffect(breathe ? 1.08 : 0.96)
                    Circle().stroke(Palette.sage.opacity(0.3), lineWidth: 1).frame(width: 220, height: 220)
                    VStack(spacing: 12) {
                        Image(systemName: store.breakFinished ? "checkmark" : "eye").font(.system(size: 34, weight: .light)).foregroundStyle(Palette.sage)
                        if store.breakFinished {
                            Text(L("잘 쉬었어요", "Nicely done")).font(.title3)
                        } else if let end = store.breakDeadline, let start = store.breakStartedAt {
                            Text(timerInterval: start...end, countsDown: true).font(.system(size: 45, weight: .light, design: .rounded)).monospacedDigit().frame(width: 150)
                        } else {
                            Text(L("20초", "20 sec")).font(.system(size: 42, weight: .light, design: .rounded))
                        }
                    }
                }.accessibilityElement(children: .combine)
                VStack(spacing: 16) {
                    guide("01", L("창밖이나 방 너머 먼 곳을 바라보세요.", "Find something far away, beyond your screen."))
                    guide("02", L("눈을 부드럽게, 천천히 깜빡여 주세요.", "Blink gently and slowly a few times."))
                    guide("03", L("어깨의 힘을 빼고 편안하게 호흡하세요.", "Relax your shoulders. Take an easy breath."))
                }.lookFarCard()
                if store.breakFinished {
                    Button(L("다음 알림 시작", "Start my next reminder")) {
                        store.clearBreak()
                        Task { await store.start() }
                    }.buttonStyle(FilledButton()).accessibilityIdentifier("nextReminder")
                    Button(L("마치기", "Done")) { store.clearBreak() }.accessibilityIdentifier("finishBreak")
                } else if store.breakDeadline == nil {
                    Button(L("20초 휴식 시작", "Start a 20-second break")) { Task { await store.beginBreak() } }
                        .buttonStyle(FilledButton()).accessibilityIdentifier("beginBreak")
                    if store.running {
                        Button(L("5분 뒤 다시 알림", "Remind me in 5 minutes")) { Task { await store.snooze() } }
                            .font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("snooze")
                    }
                } else {
                    Text(L("이제 화면에서 눈을 떼어도 좋아요.", "You can look away from your screen now."))
                        .font(.subheadline).foregroundStyle(Palette.sage)
                }
                Text(L("일상 속 휴식 습관을 돕는 앱입니다. 의료 진단이나 치료를 제공하지 않습니다.", "A gentle reminder for everyday breaks. Not a medical diagnosis or treatment."))
                    .font(.caption2).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            }.padding(25).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(Palette.background).foregroundStyle(Palette.ivory)
            .interactiveDismissDisabled()
            .task(id: store.breakDeadline) {
                guard let end = store.breakDeadline else { return }
                do { try await Task.sleep(for: .seconds(max(0, end.timeIntervalSinceNow))) }
                catch { return }
                store.checkTime()
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breathe = true }
            }
    }
    private func guide(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.caption.monospacedDigit()).foregroundStyle(Palette.coral).padding(.top, 2)
            Text(text).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        }
    }
}
