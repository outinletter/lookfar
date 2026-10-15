import SwiftUI

struct HistoryView: View {
    let store: ReminderStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text(L("작은 쉼이\n차곡차곡.", "Little breaks.\nLasting habits.")).font(.system(size: 38, weight: .semibold)).tracking(-1)
                HStack(spacing: 12) {
                    stat("\(store.today.count)", L("오늘의 휴식", "Breaks today"))
                    stat("\(store.records.count)", L("함께한 휴식", "Breaks in total"))
                }
                VStack(alignment: .leading, spacing: 22) {
                    Text(L("최근 7일", "THE LAST 7 DAYS")).font(.caption.weight(.medium)).tracking(2).foregroundStyle(Palette.muted)
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach((0..<7).reversed(), id: \.self) { offset in
                            let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
                            let count = store.records.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.count
                            VStack(spacing: 10) {
                                Text("\(count)").font(.caption2).foregroundStyle(Palette.muted)
                                RoundedRectangle(cornerRadius: 7).fill(offset == 0 ? Palette.coral : Palette.sage.opacity(0.5))
                                    .frame(height: CGFloat(min(100, max(4, count * 12))))
                                Text(day, format: .dateTime.weekday(.narrow)).font(.caption).foregroundStyle(Palette.muted)
                            }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
                                .accessibilityLabel(day.formatted(date: .abbreviated, time: .omitted) + ": \(count) " + L("회", "breaks"))
                        }
                    }.frame(height: 145, alignment: .bottom)
                }.lookFarCard()
                Text(L("휴식 기록", "YOUR BREAKS")).font(.caption.weight(.medium)).tracking(2).foregroundStyle(Palette.muted)
                if store.records.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "leaf").font(.largeTitle).foregroundStyle(Palette.sage)
                        Text(L("첫 번째 쉼을 기다려요", "Your first little break awaits")).font(.headline)
                        Text(L("20초 휴식을 완료하면 여기에 기록됩니다.", "Complete a 20-second break to start your story."))
                            .font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 25).lookFarCard()
                } else {
                    ForEach(store.records.prefix(30)) { record in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.sage)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("먼 곳 보기 · 20초", "Look far · 20 seconds")).font(.subheadline.weight(.medium))
                                Text(record.date, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                        }.lookFarCard()
                    }
                }
                Text(L("직접 시작해 완료한 휴식만 기록합니다. 모든 기록은 이 기기에만 저장됩니다.", "Only breaks you start and complete are recorded. Your history stays on this device."))
                    .font(.caption).foregroundStyle(Palette.muted)
            }.padding(25)
        }.background(Palette.background).foregroundStyle(Palette.ivory)
            .navigationTitle(L("휴식 기록", "Your breaks")).navigationBarTitleDisplayMode(.inline)
    }
    private func stat(_ value: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value).font(.system(size: 45, weight: .light, design: .rounded)).foregroundStyle(Palette.coral)
            Text(title).font(.caption).foregroundStyle(Palette.muted)
        }.lookFarCard()
    }
}
