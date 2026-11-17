import SwiftUI
import ActivityKit

enum BlinkMode: String, CaseIterable {
    case far, blink
    var title: String { self == .far ? L("멀리 보기", "Look far") : L("눈 깜빡임", "Blink") }
    var icon: String { self == .far ? "mountain.2.fill" : "eye.fill" }
    var detail: String {
        self == .far
            ? L("점이 길게 켜지면 화면에서 눈을 떼고 먼 곳을 바라보세요.", "When the dot glows long, look away at something far.")
            : L("점이 짧게 깜빡이면 그 박자에 맞춰 눈을 깜빡여 주세요.", "When the dot flashes, blink along with it.")
    }
    var patternLabel: String { self == .far ? L("길게 2번", "2 long") : L("짧게 3번 · 2회 반복", "3 short · twice") }
    var pulses: Int { self == .far ? 2 : 3 }
}

enum Server {
    // Deployed Cloudflare Worker (see server/README.md).
    static let baseURL = URL(string: "https://lookfar.outinletter.workers.dev")!
}

// Signals are sent by the server as Live Activity pushes, so nothing runs in the background.
@MainActor
final class BlinkController: ObservableObject {
    // With two modes the second follows the first after `offsetSeconds`; the pair repeats every interval.
    static func offsetSeconds(minutes: Int) -> Int { min(300, minutes * 30) }

    @Published var running = false
    @Published var working = false
    @Published var error: String?
    // When the running session started; drives the in-app countdown to the next signal.
    @Published var startedAt: Date? {
        didSet { UserDefaults.standard.set(startedAt?.timeIntervalSince1970 ?? 0, forKey: "startedAt") }
    }
    private var activity: Activity<LookFarActivity>?
    private var observers: [Task<Void, Never>] = []
    private var sessionID: String {
        get { UserDefaults.standard.string(forKey: "sessionID") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sessionID") }
    }

    init() {
        // A session keeps running on the server while the app is closed; pick it up again.
        if let existing = Activity<LookFarActivity>.activities.first, !sessionID.isEmpty {
            activity = existing
            running = true
            let saved = UserDefaults.standard.double(forKey: "startedAt")
            startedAt = saved > 0 ? Date(timeIntervalSince1970: saved) : nil
            observe(existing, config: nil)
        } else {
            // Leftover activities without a server session would never receive a signal.
            for orphan in Activity<LookFarActivity>.activities {
                Task { await orphan.end(nil, dismissalPolicy: .immediate) }
            }
        }
    }

    func start(_ modes: [BlinkMode], minutes: Int) {
        debugLog("start tapped modes=\(modes.map(\.rawValue)) running=\(running) enabled=\(ActivityAuthorizationInfo().areActivitiesEnabled)")
        guard !modes.isEmpty, !running else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            error = L("설정 > LookFar에서 실시간 현황을 켠 뒤 다시 시도해 주세요.", "Turn on Live Activities in Settings > LookFar, then try again.")
            return
        }
        do {
            let state = LookFarActivity.ContentState(lit: false)
            let new = try Activity.request(attributes: LookFarActivity(title: "LookFar"),
                                           content: .init(state: state, staleDate: nil), pushType: .token)
            activity = new
            sessionID = UUID().uuidString
            running = true
            working = true
            startedAt = Date()
            observe(new, config: ["modes": modes.map(\.rawValue), "minutes": minutes])
        } catch {
            debugLog("Activity.request failed: \(error)")
            self.error = L("실시간 현황을 시작하지 못했습니다.", "Could not start the Live Activity.")
        }
    }

    func stop(_ reason: String = "user") {
        debugLog("stop reason=\(reason)")
        observers.forEach { $0.cancel() }
        observers = []
        let ended = activity
        let id = sessionID
        activity = nil
        running = false
        working = false
        startedAt = nil
        sessionID = ""
        Task {
            await ended?.end(nil, dismissalPolicy: .immediate)
            if !id.isEmpty { try? await Self.send("DELETE", id: id, body: nil) }
        }
    }

    private func observe(_ activity: Activity<LookFarActivity>, config: [String: Any]?) {
        let id = sessionID
        observers = [
            Task { [weak self] in
                var pending = config
                for await data in activity.pushTokenUpdates {
                    var body = pending ?? [:]
                    body["token"] = data.map { String(format: "%02x", $0) }.joined()
                    #if DEBUG
                    body["sandbox"] = true
                    #endif
                    debugLog("push token received, config=\(pending != nil)")
                    do {
                        try await Self.send("POST", id: id, body: body)
                        debugLog("server accepted")
                        pending = nil
                        self?.working = false
                    } catch {
                        debugLog("server error: \(error)")
                        if pending != nil { self?.fail() ; return }
                        // The server already dropped this session (8-hour limit), so end it here too.
                        if error is SessionGone { self?.stop("session gone") ; return }
                    }
                }
            },
            Task { [weak self] in
                for await state in activity.activityStateUpdates {
                    debugLog("activity state: \(state)")
                    if state == .ended || state == .dismissed { self?.stop("activity \(state)") ; return }
                }
            },
            Task { [weak self] in
                // No push token or no server answer in time.
                try? await Task.sleep(for: .seconds(20))
                if !Task.isCancelled, self?.working == true { debugLog("timeout waiting for token/server") ; self?.fail() }
            }
        ]
    }

    private func fail() {
        stop("fail")
        error = L("신호 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.", "Could not reach the signal server. Check your internet connection and try again.")
    }

    private static func send(_ method: String, id: String, body: [String: Any]?) async throws {
        var request = URLRequest(url: Server.baseURL.appending(path: "session/\(id)"))
        request.httpMethod = method
        request.timeoutInterval = 15
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode
        if status == 404 { throw SessionGone() }
        guard status == 200 else { throw URLError(.badServerResponse) }
    }
}

struct SessionGone: Error {}

func debugLog(_ message: String) {
    #if DEBUG
    print("[LookFar] \(message)")
    #endif
}

enum Pastel {
    static let background = Color(red: 0.075, green: 0.045, blue: 0.09)
    static let surface = Color(red: 0.13, green: 0.095, blue: 0.145)
    static let ink = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let muted = Color(red: 0.69, green: 0.64, blue: 0.70)
    static let onAccent = Color(red: 0.25, green: 0.15, blue: 0.12)
    // Pastel orange (peach) replaces the former saturated coral/orange accent.
    static let accent = Color(red: 1.0, green: 0.78, blue: 0.62)
    static let mint = Color(red: 0.70, green: 0.86, blue: 0.78)
    static let lavender = Color(red: 0.79, green: 0.75, blue: 0.93)
    static let rose = Color(red: 0.97, green: 0.74, blue: 0.76)
    static func tint(_ mode: BlinkMode) -> Color { mode == .far ? mint : lavender }
}

struct RootView: View {
    @StateObject private var blink = BlinkController()
    @AppStorage("intervalMinutes") private var minutes = 20
    @AppStorage("useFar") private var useFar = true
    @AppStorage("useBlink") private var useBlink = false
    @State private var hasIsland = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                intervalPicker
                VStack(spacing: 10) {
                    ForEach(BlinkMode.allCases, id: \.self) { modeCard($0) }
                    // Always laid out so the content below does not shift when the selection changes.
                    Text(L("둘 다 고르면 멀리 보기 신호 \(offsetText) 뒤에 눈 깜빡임 신호가 이어집니다.", "With both on, Blink follows Look far after \(offsetText)."))
                        .font(.caption).foregroundStyle(Pastel.muted).lineLimit(1).minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(selected.count > 1 ? 1 : 0).accessibilityHidden(selected.count < 2)
                }
                startButton
                howTo
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
        }
        .scrollBounceBehavior(.basedOnSize).background(Pastel.background.ignoresSafeArea())
        .foregroundStyle(Pastel.ink)
        .alert(L("신호를 시작할 수 없습니다", "Cannot start signals"), isPresented: Binding(get: { blink.error != nil }, set: { if !$0 { blink.error = nil } })) {
            Button(L("설정 열기", "Open Settings")) { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button(L("닫기", "Close"), role: .cancel) {}
        } message: { Text(blink.error ?? "") }
        .onAppear { detectIsland() }
    }

    // Devices without a Dynamic Island show the dot in the Lock Screen Live Activity instead.
    // Read once after the view appears: querying the window while body is evaluated stops SwiftUI updates.
    private func detectIsland() {
        let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        hasIsland = (window?.safeAreaInsets.top ?? 59) >= 51
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(Pastel.accent).frame(width: 14, height: 14)
                Text("LOOKFAR").font(.system(size: 24, weight: .heavy, design: .rounded)).tracking(4)
            }
            Text(L("오래 보는 눈에게 작은 신호 하나.", "A small signal for busy eyes."))
                .font(.system(size: 23, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(L("유튜브처럼 화면을 오래 볼 때, 다이내믹 아일랜드의 노란 점이 눈을 쉬게 할 때를 알려 줍니다.", "While you watch for a long time, a yellow dot in the Dynamic Island tells you when to rest your eyes."))
                .font(.footnote).foregroundStyle(Pastel.muted).lineSpacing(3)
        }
    }

    private var selected: [BlinkMode] { BlinkMode.allCases.filter(isOn) }
    private func isOn(_ mode: BlinkMode) -> Bool { mode == .far ? useFar : useBlink }
    private var offsetText: String {
        let seconds = BlinkController.offsetSeconds(minutes: minutes)
        return seconds % 60 == 0 ? L("\(seconds / 60)분", "\(seconds / 60) min") : L("\(seconds / 60)분 \(seconds % 60)초", "\(seconds / 60) min \(seconds % 60) sec")
    }
    private func binding(_ mode: BlinkMode) -> Binding<Bool> {
        Binding(get: { isOn(mode) }, set: { value in
            if mode == .far { useFar = value } else { useBlink = value }
        })
    }

    private func modeCard(_ mode: BlinkMode) -> some View {
        let on = isOn(mode)
        return HStack(spacing: 12) {
            Image(systemName: mode.icon).font(.body).foregroundStyle(Pastel.tint(mode))
                .frame(width: 38, height: 38).background(Pastel.tint(mode).opacity(0.28), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(mode.title).font(.headline)
                    pattern(mode)
                    Text(mode.patternLabel).font(.caption2).foregroundStyle(Pastel.muted).lineLimit(1)
                }
                Text(mode.detail).font(.caption).foregroundStyle(Pastel.muted)
                    .lineSpacing(2).multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Toggle(mode.title, isOn: binding(mode)).labelsHidden()
                .tint(Color(red: 0.55, green: 0.80, blue: 0.68)).disabled(blink.running)
        }
        .padding(.horizontal, 14).padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
        .background(on ? Pastel.tint(mode).opacity(0.22) : Pastel.surface, in: RoundedRectangle(cornerRadius: 20))
        .opacity(blink.running && !on ? 0.5 : 1)
    }

    private var startButton: some View {
        VStack(spacing: 10) {
            Button {
                if blink.running { blink.stop() } else { blink.start(selected, minutes: minutes) }
            } label: {
                HStack(spacing: 8) {
                    if blink.working { ProgressView().tint(Pastel.onAccent) }
                    else { Image(systemName: blink.running ? "stop.fill" : "play.fill") }
                    Text(blink.running ? L("신호 끄기", "Stop signals") : L("신호 시작", "Start signals"))
                }
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(blink.running ? Pastel.rose : Pastel.accent, in: RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(Pastel.onAccent)
            }.buttonStyle(.plain).disabled(blink.working || (selected.isEmpty && !blink.running))
                .opacity(selected.isEmpty && !blink.running ? 0.45 : 1)
            statusLine.lineLimit(1).minimumScaleFactor(0.8).frame(height: 20)
        }
    }

    // Fixed-height line: countdown while running, hint when nothing is selected, otherwise blank.
    @ViewBuilder private var statusLine: some View {
        if blink.running, let started = blink.startedAt {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let next = nextSignal(elapsed: context.date.timeIntervalSince(started))
                Text(L("다음 신호 · \(next.mode.title) · \(clock(next.remaining))", "Next: \(next.mode.title) in \(clock(next.remaining))"))
                    .font(.subheadline.weight(.semibold)).monospacedDigit().foregroundStyle(Pastel.accent)
            }
        } else {
            Text(L("신호를 하나 이상 켜 주세요.", "Turn on at least one signal."))
                .font(.caption).foregroundStyle(Pastel.muted)
                .opacity(selected.isEmpty && !blink.running ? 1 : 0).accessibilityHidden(!selected.isEmpty || blink.running)
        }
    }

    // Mirrors the server schedule: first signal one interval after start, the second mode `offset` later.
    private func nextSignal(elapsed: TimeInterval) -> (mode: BlinkMode, remaining: Int) {
        let interval = Double(minutes * 60)
        let offset = Double(BlinkController.offsetSeconds(minutes: minutes))
        let modes = selected.isEmpty ? [BlinkMode.far] : selected
        var best: (mode: BlinkMode, wait: Double) = (modes[0], .infinity)
        for (index, mode) in modes.enumerated() {
            let phase = index == 0 ? 0 : offset
            let first = interval + phase
            let wait = elapsed < first ? first - elapsed : interval - (elapsed - phase).truncatingRemainder(dividingBy: interval)
            if wait < best.wait { best = (mode, wait) }
        }
        return (best.mode, max(0, Int(best.wait.rounded(.up))))
    }
    private func clock(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }

    private var intervalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("신호 간격", "Signal interval")).font(.footnote.weight(.semibold)).foregroundStyle(Pastel.muted)
            HStack(spacing: 8) {
                ForEach([5, 10, 20, 30], id: \.self) { value in
                    Button { minutes = value } label: {
                        Text(L("\(value)분", "\(value) min")).font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(minutes == value ? Pastel.accent : Pastel.surface, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(minutes == value ? Pastel.onAccent : Pastel.muted)
                    }.buttonStyle(.plain)
                }
            }
        }
        .disabled(blink.running).opacity(blink.running ? 0.5 : 1)
    }

    private func pattern(_ mode: BlinkMode) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<mode.pulses, id: \.self) { _ in
                Capsule().fill(Pastel.accent).frame(width: mode == .far ? 16 : 5, height: 5)
                    
            }
        }
    }

    private var howTo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("사용 방법", "How it works")).font(.footnote.weight(.semibold)).foregroundStyle(Pastel.muted)
            step(1, L("간격과 신호를 고르고 신호 시작을 누릅니다.", "Pick an interval and signals, then tap Start signals."))
            step(2, L("보던 영상이나 앱으로 돌아갑니다.", "Go back to your video or app."))
            step(3, L("간격만큼 시간이 지날 때마다 신호가 켜집니다.", "The signal lights up each time the interval passes."))
            Text(hasIsland
                 ? L("끝내려면 앱에서 신호 끄기를 누르세요. 노란 점은 다른 앱을 쓰는 동안 보이며, 인터넷 연결이 필요합니다.", "Tap Stop signals in the app to finish. The dot shows while you use other apps and needs an internet connection.")
                 : L("이 기기에는 다이내믹 아일랜드가 없어 잠금 화면의 실시간 현황에서 노란 점이 켜집니다. 인터넷 연결이 필요합니다.", "This device has no Dynamic Island, so the yellow dot appears in the Lock Screen Live Activity. An internet connection is required."))
                .font(.caption2).foregroundStyle(Pastel.muted)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Pastel.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)").font(.caption.weight(.bold)).foregroundStyle(Pastel.onAccent)
                .frame(width: 20, height: 20).background(Pastel.accent, in: Circle())
            Text(text).font(.footnote)
        }
    }
}
