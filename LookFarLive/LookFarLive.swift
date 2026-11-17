import WidgetKit
import SwiftUI
import ActivityKit

struct YellowDot: View {
    let lit: Bool
    var size: CGFloat = 10
    var body: some View {
        Circle().fill(Color.yellow).frame(width: size, height: size).opacity(lit ? 1 : 0)
    }
}

@main
struct LookFarLive: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LookFarActivity.self) { context in
            // Lock Screen / banner presentation, also used on devices without a Dynamic Island.
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color.yellow.opacity(0.35), lineWidth: 1.5).frame(width: 18, height: 18)
                    YellowDot(lit: context.state.lit, size: 12)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("LookFar").font(.subheadline.weight(.semibold))
                    Text(context.state.lit
                         ? L("지금 눈을 쉬어 주세요", "Time to rest your eyes")
                         : L("눈 휴식 신호 대기 중", "Waiting for your next eye-break signal"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 0.13, green: 0.095, blue: 0.145))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { YellowDot(lit: context.state.lit, size: 12).padding(.leading, 6) }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.lit
                         ? L("지금 눈을 쉬어 주세요", "Time to rest your eyes")
                         : L("눈 휴식 신호 대기 중", "Waiting for your next signal"))
                        .font(.caption)
                }
            } compactLeading: {
                YellowDot(lit: context.state.lit)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                YellowDot(lit: context.state.lit)
            }
        }
    }
}
