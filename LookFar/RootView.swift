import SwiftUI

struct RootView: View {
    @Bindable var store: ReminderStore
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack { FocusView(store: store) }
                .tabItem { Label(L("타이머", "Timer"), systemImage: "sun.horizon") }.tag(0)
            NavigationStack { HistoryView(store: store) }
                .tabItem { Label(L("휴식 기록", "Your breaks"), systemImage: "chart.bar.xaxis") }.tag(1)
            NavigationStack { SettingsView(store: store) }
                .tabItem { Label(L("설정", "Settings"), systemImage: "slider.horizontal.3") }.tag(2)
        }
        .fullScreenCover(isPresented: $store.showingBreak) { BreakView(store: store) }
        .task {
            await store.refresh()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                // Read live application state: a long-lived task can retain the initial scenePhase value.
                if UIApplication.shared.applicationState == .active { store.checkTime() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refresh() } }
        }
        .alert(L("알림 확인", "Check notifications"), isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button(L("설정 열기", "Open Settings")) { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button(L("닫기", "Close"), role: .cancel) { store.error = nil }
        } message: { Text(store.error ?? "") }
    }
}

struct FocusView: View {
    @Bindable var store: ReminderStore
    @State private var custom = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    HStack(spacing: 9) {
                        Image("BrandIcon").resizable().frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("LOOKFAR").font(.system(size: 17, weight: .bold, design: .rounded)).tracking(3)
                    }
                    Spacer()
                    Label(L("나만의 작은 휴식", "A little room to rest"), systemImage: "leaf")
                        .font(.caption2).foregroundStyle(Palette.sage)
                }.padding(.top, 12)
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.running ? L("집중은 가볍게.\n휴식은 잊지 않게.", "Find your focus.\nKeep your distance.") : L("잠깐,\n시선을 멀리.", "A little distance.\nA little rest."))
                        .font(.system(size: 40, weight: .semibold)).tracking(-1.6).fixedSize(horizontal: false, vertical: true)
                    Text(L("화면 너머의 세상을 바라볼 시간.", "Make time for the world beyond your screen."))
                        .font(.subheadline).foregroundStyle(Palette.muted)
                }
                timerCard
                if let notice = store.activityNotice, store.running {
                    Label(notice, systemImage: "info.circle").font(.caption).foregroundStyle(Palette.muted)
                }
                if !store.running { intervalSelector }
                VStack(spacing: 14) {
                    Button {
                        Task { if store.running { await store.stop() } else { await store.start() } }
                    } label: {
                        HStack(spacing: 10) {
                            if store.isWorking { ProgressView() }
                            else { Image(systemName: store.running ? "stop.fill" : "play.fill") }
                            Text(store.running ? L("타이머 종료", "End timer") : L("눈 휴식 알림 시작", "Start my reminder"))
                        }
                    }.buttonStyle(FilledButton()).disabled(store.isWorking).accessibilityIdentifier("startStop")
                    Button(L("지금 눈 쉬기", "Take a break now")) { store.showingBreak = true }
                        .font(.subheadline.weight(.medium)).foregroundStyle(Palette.ivory)
                        .padding(.vertical, 6).accessibilityIdentifier("breakNow")
                }
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "bell.badge").font(.title3).foregroundStyle(Palette.coral)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("다른 앱을 사용해도 알려드려요", "Your reminder travels with you")).font(.subheadline.weight(.semibold))
                        Text(L("정한 시간이 지나면 LOOKFAR 알림이 도착합니다. 집중 모드와 알림 설정에 따라 표시가 달라질 수 있어요.", "A LOOKFAR notification arrives when your timer ends, even in another app. Focus and notification settings can affect delivery."))
                            .font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                    }
                }.lookFarCard()
                Text(L("오늘의 작은 실천", "LITTLE MOMENTS, TODAY")).font(.caption.weight(.medium)).tracking(2).foregroundStyle(Palette.muted)
                HStack {
                    Label("\(store.today.count) " + L("번의 휴식", "breaks"), systemImage: "sparkles")
                    Spacer()
                    Text("\(store.today.reduce(0) { $0 + $1.seconds })" + L("초", " sec"))
                }.font(.subheadline).foregroundStyle(Palette.sage).padding(.bottom, 12)
            }.padding(.horizontal, 25).padding(.bottom, 20)
        }
        .background(Palette.background).foregroundStyle(Palette.ivory)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $custom) {
            NavigationStack {
                VStack(spacing: 25) {
                    Text(L("나에게 맞는 간격", "Find your rhythm")).font(.title2.weight(.semibold))
                    Picker(L("알림 간격", "Reminder interval"), selection: $store.minutes) {
                        ForEach(1...180, id: \.self) { Text("\($0) " + L("분", "min")).tag($0) }
                    }.pickerStyle(.wheel).accessibilityIdentifier("minutesPicker")
                    Button(L("이 간격으로 설정", "Use this interval")) { custom = false }.buttonStyle(FilledButton())
                }.padding(28).toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("닫기", "Close")) { custom = false } } }
            }.presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
    }
    private var timerCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(store.running ? L("다음 눈 휴식까지", "YOUR NEXT EYE BREAK") : L("나의 휴식 간격", "YOUR REST RHYTHM"))
                    .font(.caption.weight(.medium)).tracking(2).foregroundStyle(Palette.muted)
                if let deadline = store.deadline {
                    Text(timerInterval: (store.startedAt ?? Date())...deadline, countsDown: true)
                        .font(.system(size: 67, weight: .light, design: .rounded)).monospacedDigit()
                        .accessibilityIdentifier("countdown")
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(store.minutes)").font(.system(size: 80, weight: .light, design: .rounded))
                        Text(L("분", "min")).font(.title3).foregroundStyle(Palette.muted)
                    }
                }
                Label(store.running ? L("알림 예약됨 · 앱을 닫아도 괜찮아요", "Scheduled · feel free to leave the app") : L("작은 알림 하나로 만드는 좋은 습관", "A gentle nudge toward a better habit"), systemImage: store.running ? "checkmark.circle.fill" : "wind")
                    .font(.caption).foregroundStyle(store.running ? Palette.sage : Palette.muted)
            }.padding(.top, 27).padding(.horizontal, 15)
            Image("WindowLandscape")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .accessibilityLabel(L("창틀 너머로 보이는 먼 산과 호수", "Distant mountains and a lake beyond a window frame"))
                .accessibilityIdentifier("windowLandscape")
                .padding(.top, 20)
        }.background(Palette.card).clipShape(RoundedRectangle(cornerRadius: 30))
    }
    private var intervalSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("알림 간격", "Remind me in")).font(.subheadline.weight(.medium))
                Spacer()
                Button(L("직접 설정", "Custom")) { custom = true }.font(.caption).foregroundStyle(Palette.coral).accessibilityIdentifier("customInterval")
            }
            HStack(spacing: 9) {
                ForEach([10, 20, 30, 45], id: \.self) { value in
                    Button { store.minutes = value } label: {
                        Text("\(value)" + L("분", "m")).font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(store.minutes == value ? Palette.ivory : Palette.card, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(store.minutes == value ? Palette.background : Palette.muted)
                    }.accessibilityIdentifier("interval\(value)").accessibilityAddTraits(store.minutes == value ? .isSelected : [])
                }
            }
        }
    }
}
