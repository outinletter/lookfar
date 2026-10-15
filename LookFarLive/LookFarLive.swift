import WidgetKit
import SwiftUI
import ActivityKit

@main
struct LookFarLive: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LookFarActivity.self) { context in
            HStack(spacing: 15) {
                Image(systemName: "sun.horizon.fill").font(.title).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 5) {
                    Text("LOOKFAR").font(.caption.weight(.bold)).tracking(2)
                    Text(context.isStale ? String(localized: "Time to look far") : context.attributes.title).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(timerInterval: context.state.start...context.state.deadline, countsDown: true)
                    .font(.system(.title2, design: .rounded).weight(.medium)).monospacedDigit().frame(width: 95)
            }.padding(20)
                .activityBackgroundTint(Color(red: 0.13, green: 0.095, blue: 0.145))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("LOOKFAR", systemImage: "sun.horizon.fill").font(.headline).foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.start...context.state.deadline, countsDown: true)
                        .font(.system(.title2, design: .rounded)).monospacedDigit().frame(width: 95)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.isStale ? String(localized: "Time to look far") : context.attributes.title).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "eye").foregroundStyle(.orange)
                    }.padding(.top, 8)
                    ProgressView(timerInterval: context.state.start...context.state.deadline, countsDown: false).tint(.orange).labelsHidden()
                }
            } compactLeading: {
                Image(systemName: "sun.horizon.fill").foregroundStyle(.orange)
            } compactTrailing: {
                if context.isStale {
                    Text("REST").font(.caption2.weight(.bold)).foregroundStyle(.orange)
                } else {
                    Text(timerInterval: context.state.start...context.state.deadline, countsDown: true)
                        .font(.caption2.monospacedDigit()).foregroundStyle(.orange).frame(width: 46)
                }
            } minimal: {
                Image(systemName: "eye").foregroundStyle(.orange)
            }.keylineTint(.orange)
        }
    }
}
