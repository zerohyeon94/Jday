import Foundation
import UserNotifications
import SwiftData
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

    /// 일정 알림을 중요도에 맞춰 예약한다.
    /// - 낮음: 10분 전 1회, 조용히(.passive)
    /// - 보통: 기본 리드타임 1회(.active)
    /// - 높음: 하루 전·1시간 전·기본 리드타임 여러 번, 집중 모드도 뚫는 .timeSensitive
    /// 하나의 일정이 여러 알림을 가질 수 있어 식별자를 `schedule-<id>-<offset>`으로 분리한다.
    func scheduleScheduleNotification(for schedule: Schedule) {
        guard schedule.startTime > .now else { return }

        let base = resolvedBaseMinutes()
        let offsets = reminderOffsets(for: schedule.priority, base: base)
        let level = interruptionLevel(for: schedule.priority)

        for minutesBefore in offsets {
            guard let notifyAt = Calendar.current.date(
                byAdding: .minute,
                value: -minutesBefore,
                to: schedule.startTime
            ), notifyAt > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "일정 알림")
            content.body = "\(leadTimeLabel(minutes: minutesBefore)) 후: \(schedule.title)"
            content.sound = .default
            content.interruptionLevel = level

            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notifyAt
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let identifier = "schedule-\(schedule.persistentModelID)-\(minutesBefore)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    logger.error("일정 알림 등록 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelScheduleNotification(for schedule: Schedule) {
        // offset별로 여러 알림이 예약되어 있으므로 `schedule-<id>-` 프리픽스로 모두 취소한다.
        let prefix = "schedule-\(schedule.persistentModelID)-"
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            guard !ids.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - 아침 요약 알림

    /// 설정 키 (UserDefaults.standard — SettingsView의 @AppStorage와 공유).
    enum MorningSummaryKey {
        static let enabled = "morningSummaryEnabled"
        static let hour = "morningSummaryHour"
        static let minute = "morningSummaryMinute"
    }

    /// 아침 요약 알림을 다시 예약한다(향후 7일 롤링). 앱 활성화·설정 변경 시 호출.
    /// 서버 없이 각 날짜의 할 일·일정 개수를 미리 계산해 로컬 알림으로 예약한다.
    func refreshMorningSummaries(context: ModelContext) {
        cancelMorningSummaries()

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: MorningSummaryKey.enabled) else { return }

        let hour = defaults.object(forKey: MorningSummaryKey.hour) as? Int ?? 8
        let minute = defaults.object(forKey: MorningSummaryKey.minute) as? Int ?? 0

        let tasks = (try? context.fetch(FetchDescriptor<DailyTask>())) ?? []
        let schedules = (try? context.fetch(FetchDescriptor<Schedule>())) ?? []

        let wsEnabled = AppGroup.defaults.bool(forKey: "workspaceSeparationEnabled")
        let wsActive = Workspace(rawValue: AppGroup.defaults.string(forKey: "activeWorkspace") ?? "") ?? .personal
        let filteredTasks = tasks.workspaceFiltered(enabled: wsEnabled, active: wsActive)
        let filteredSchedules = schedules.workspaceFiltered(enabled: wsEnabled, active: wsActive)

        let calendar = Calendar.current
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            guard let fireDate = calendar.date(from: comps), fireDate > .now else { continue }

            let taskCount = filteredTasks.filter { $0.date.isSameDay(as: day) && !$0.isDone }.count
            let scheduleCount = filteredSchedules.filter { $0.occurs(on: day) }.count

            let content = UNMutableNotificationContent()
            content.title = String(localized: "오늘의 계획")
            content.body = summaryBody(taskCount: taskCount, scheduleCount: scheduleCount)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = "morning-summary-\(Int(day.startOfDay.timeIntervalSince1970))"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    logger.error("아침 요약 알림 등록 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelMorningSummaries() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("morning-summary-") }
            guard !ids.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func summaryBody(taskCount: Int, scheduleCount: Int) -> String {
        if taskCount == 0 && scheduleCount == 0 {
            return String(localized: "오늘은 등록된 할 일과 일정이 없어요. 좋은 하루 되세요!")
        }
        return String(localized: "오늘 할 일 \(taskCount)개, 일정 \(scheduleCount)개가 있어요.")
    }

    // MARK: - 중요도 매핑

    /// 사용자 설정(notifyMinutesBefore)을 기본 리드타임으로 사용. 미설정 시 30분.
    private func resolvedBaseMinutes() -> Int {
        let stored = UserDefaults.standard.integer(forKey: "notifyMinutesBefore")
        return stored > 0 ? stored : 30
    }

    /// 중요도별 "몇 분 전" 미리 알림 목록(중복 제거, 내림차순).
    private func reminderOffsets(for priority: Priority, base: Int) -> [Int] {
        switch priority {
        case .low:
            return [10]
        case .medium:
            return [base]
        case .high:
            // 하루 전(1440) · 1시간 전(60) · 기본 리드타임
            return Array(Set([1440, 60, base])).sorted(by: >)
        }
    }

    private func interruptionLevel(for priority: Priority) -> UNNotificationInterruptionLevel {
        switch priority {
        case .low: return .passive
        case .medium: return .active
        case .high: return .timeSensitive
        }
    }

    /// 리드타임을 사람이 읽기 쉬운 라벨로. 60분 이상은 시간/일 단위로 표기.
    private func leadTimeLabel(minutes: Int) -> String {
        if minutes >= 1440, minutes % 1440 == 0 {
            return String(localized: "\(minutes / 1440)일")
        }
        if minutes >= 60, minutes % 60 == 0 {
            return String(localized: "\(minutes / 60)시간")
        }
        return String(localized: "\(minutes)분")
    }
}
