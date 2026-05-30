import SwiftUI
import SwiftData

struct TodayScheduleView: View {
    let schedules: [Schedule]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 일정")
                .font(.headline)

            if schedules.isEmpty {
                Text("일정 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(schedules) { schedule in
                    scheduleRow(schedule)
                }
            }
        }
    }

    private func scheduleRow(_ schedule: Schedule) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.title)
                    .font(.subheadline)
                    .foregroundStyle(schedule.isPast ? .secondary : .primary)

                Text("\(schedule.startTime.formattedTime) – \(schedule.endTime.formattedTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let location = schedule.location {
                    Label(location, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .opacity(schedule.isPast ? 0.4 : 1.0)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(schedule.title), \(schedule.startTime.formattedTime)부터 \(schedule.endTime.formattedTime)")
    }
}
