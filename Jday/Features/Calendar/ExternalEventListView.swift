import SwiftUI

/// Apple 캘린더 이벤트 읽기 전용 목록 카드 — 홈·캘린더에서 공용.
/// Jday 일정과 구분되도록 캘린더 색상 바 + 캘린더 이름을 함께 표시한다.
struct ExternalEventListView: View {
    let events: [ExternalEvent]
    var showHeader: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if showHeader {
                CardHeader(title: "Apple 캘린더", trailing: "\(events.count)개")
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(events) { event in
                    ExternalEventRow(event: event)
                }
            }
        }
        .cardStyle()
    }
}

private struct ExternalEventRow: View {
    let event: ExternalEvent

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(event.isAllDay ? String(localized: "종일") : event.startTime.hourMinuteLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
                .padding(.top, 2)

            RoundedRectangle(cornerRadius: 2)
                .fill(event.calendarColor)
                .frame(width: 3)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(event.isPast ? .secondary : .primary)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(event.calendarTitle)
                        .font(.caption)
                        .foregroundStyle(event.calendarColor)

                    if let location = event.location, !location.isEmpty {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .opacity(event.isPast ? 0.4 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.isAllDay ? String(localized: "종일") : event.startTime.hourMinuteLabel), \(event.title), Apple 캘린더")
    }
}

#Preview {
    ExternalEventListView(events: [
        ExternalEvent(
            id: "1", title: "치과 예약",
            startTime: .now.addingTimeInterval(3600), endTime: .now.addingTimeInterval(7200),
            isAllDay: false, calendarTitle: "개인", calendarColor: .orange, location: "강남역"
        ),
        ExternalEvent(
            id: "2", title: "가족 여행",
            startTime: .now.startOfDay, endTime: .now.endOfDay,
            isAllDay: true, calendarTitle: "가족", calendarColor: .purple, location: nil
        )
    ])
    .padding()
    .background(Theme.Colors.appBackground)
}
