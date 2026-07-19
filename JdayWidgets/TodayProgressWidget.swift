import WidgetKit
import SwiftUI

/// 오늘 요약 — 홈 소형(진행률 링 + 카운트) / 잠금화면 원형(진행률 Gauge).
struct TodayProgressWidget: Widget {
    let kind = "TodayProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JdayTimelineProvider()) { entry in
            TodayProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘 요약")
        .description("오늘 할 일 진행률과 일정 수를 보여줘요.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct TodayProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: JdayTimelineEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        default:
            smallView
        }
    }

    private var circularView: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "checklist")
        } currentValueLabel: {
            Text("\(entry.remainingCount)")
        }
        .gaugeStyle(.accessoryCircular)
        .accessibilityLabel(Text("오늘 할 일 진행률"))
        .accessibilityValue(Text("남은 할 일 \(entry.remainingCount)개"))
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date.shortMonthDay)
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(entry.remainingCount)")
                        .font(.title2.bold())
                    Text("남음")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Label {
                Text("일정 \(entry.schedules.count)개")
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel(Text("오늘 요약"))
        .accessibilityValue(Text("남은 할 일 \(entry.remainingCount)개, 일정 \(entry.schedules.count)개"))
    }
}

#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    JdayTimelineEntry.preview
}
