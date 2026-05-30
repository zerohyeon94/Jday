import SwiftUI
import SwiftData

struct TodayScheduleView: View {
    let schedules: [Schedule]
    var showHeader: Bool = true

    private var sorted: [Schedule] {
        schedules.sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if showHeader {
                CardHeader(title: "오늘 일정", trailing: schedules.isEmpty ? nil : "\(schedules.count)개")
            }

            if schedules.isEmpty {
                Text("일정 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.md)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sorted.enumerated()), id: \.element.persistentModelID) { index, schedule in
                        TimelineRow(
                            schedule: schedule,
                            isFirst: index == 0,
                            isLast: index == sorted.count - 1
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
}

private struct TimelineRow: View {
    let schedule: Schedule
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(schedule.startTime.hourMinuteLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
                .padding(.top, 2)

            timelineMarker

            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(schedule.isPast ? .secondary : .primary)

                if let location = schedule.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, isLast ? 0 : Theme.Spacing.lg)

            Spacer(minLength: 0)
        }
        .opacity(schedule.isPast ? 0.4 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(schedule.startTime.hourMinuteLabel), \(schedule.title)")
    }

    private var timelineMarker: some View {
        VStack(spacing: 0) {
            Circle()
                .strokeBorder(Theme.Colors.brand, lineWidth: 2)
                .background(Circle().fill(schedule.isPast ? Color.clear : Theme.Colors.brand))
                .frame(width: 10, height: 10)
                .padding(.top, 3)

            if !isLast {
                Rectangle()
                    .fill(Theme.Colors.cardStroke)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 10)
    }
}

#Preview {
    TodayScheduleView(schedules: PreviewHelpers.sampleSchedules)
        .padding()
        .background(Theme.Colors.appBackground)
}
