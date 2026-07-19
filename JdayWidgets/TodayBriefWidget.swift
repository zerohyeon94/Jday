import WidgetKit
import SwiftUI

/// 오늘 브리핑 — 잠금화면 직사각형(할 일 + 다음 일정) / 인라인(한 줄 요약).
struct TodayBriefWidget: Widget {
    let kind = "TodayBriefWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JdayTimelineProvider()) { entry in
            TodayBriefWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘 브리핑")
        .description("잠금화면에서 남은 할 일과 다음 일정을 확인해요.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct TodayBriefWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: JdayTimelineEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(inlineText)
        default:
            rectangularView
        }
    }

    private var inlineText: String {
        if let next = entry.nextSchedule {
            return "\(next.startTime.hourMinuteLabel) \(next.title)"
        }
        if entry.remainingCount > 0 {
            return String(localized: "할 일 \(entry.remainingCount)개 남음")
        }
        return String(localized: "오늘 일정·할 일 없음")
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(entry.remainingCount > 0 ? "할 일 \(entry.remainingCount)개 남음" : "할 일 완료!")
                    .font(.headline)
            } icon: {
                Image(systemName: "checklist")
            }
            if let next = entry.nextSchedule {
                Text("\(next.startTime.hourMinuteLabel) \(next.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("남은 일정 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(Text("오늘 브리핑"))
    }
}

#Preview(as: .accessoryRectangular) {
    TodayBriefWidget()
} timeline: {
    JdayTimelineEntry.preview
}
