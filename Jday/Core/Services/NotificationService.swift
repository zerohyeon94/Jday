import Foundation
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "NotificationService")

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            logger.error("알림 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleIssueNotification(for issue: Issue) {
        guard let notifyAt = issue.notifyAt, notifyAt > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "이슈 알림")
        content.body = issue.title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notifyAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = "issue-\(issue.persistentModelID)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("이슈 알림 등록 실패: \(error.localizedDescription)")
            }
        }
    }

    func cancelIssueNotification(for issue: Issue) {
        let identifier = "issue-\(issue.persistentModelID)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func scheduleScheduleNotification(for schedule: Schedule, minutesBefore: Int = 30) {
        guard schedule.startTime > .now else { return }
        guard let notifyAt = Calendar.current.date(
            byAdding: .minute,
            value: -minutesBefore,
            to: schedule.startTime
        ), notifyAt > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "일정 알림")
        content.body = "\(minutesBefore)분 후: \(schedule.title)"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notifyAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = "schedule-\(schedule.persistentModelID)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("일정 알림 등록 실패: \(error.localizedDescription)")
            }
        }
    }
}
