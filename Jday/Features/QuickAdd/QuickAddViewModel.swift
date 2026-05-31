import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "QuickAddViewModel")

enum QuickAddTab: String, CaseIterable {
    case task = "할 일"
    case schedule = "일정"
    case issue = "이슈"
}

@MainActor
final class QuickAddViewModel: ObservableObject {
    @Published var selectedTab: QuickAddTab = .task
    @Published var errorMessage: String?

    // 할 일
    @Published var taskTitle = ""
    @Published var taskDetail = ""
    @Published var taskDate = Date.now
    @Published var taskPriority = Priority.medium

    // 일정
    @Published var scheduleTitle = ""
    @Published var scheduleStartTime = Date.now
    @Published var scheduleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
    @Published var scheduleLocation = ""

    // 이슈
    @Published var issueTitle = ""
    @Published var issueDetail = ""
    @Published var issueNotifyAt: Date? = nil
    @Published var issueHasNotify = false

    var canSaveTask: Bool { !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty }
    var canSaveSchedule: Bool {
        !scheduleTitle.trimmingCharacters(in: .whitespaces).isEmpty
        && scheduleEndTime > scheduleStartTime
    }
    var canSaveIssue: Bool { !issueTitle.trimmingCharacters(in: .whitespaces).isEmpty }

    var isPastNotifyTime: Bool {
        guard issueHasNotify, let notifyAt = issueNotifyAt else { return false }
        return notifyAt <= .now
    }

    func saveTask(context: ModelContext) -> Bool {
        guard canSaveTask else { return false }
        let trimmedDetail = taskDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = DailyTask(
            title: taskTitle.trimmingCharacters(in: .whitespaces),
            detail: trimmedDetail.isEmpty ? nil : trimmedDetail,
            date: taskDate,
            priority: taskPriority
        )
        context.insert(task)
        return save(context: context)
    }

    func saveSchedule(context: ModelContext) -> Bool {
        guard canSaveSchedule else { return false }
        let schedule = Schedule(
            title: scheduleTitle.trimmingCharacters(in: .whitespaces),
            startTime: scheduleStartTime,
            endTime: scheduleEndTime,
            location: scheduleLocation.isEmpty ? nil : scheduleLocation
        )
        context.insert(schedule)
        let saved = save(context: context)
        if saved {
            NotificationService.shared.scheduleScheduleNotification(for: schedule)
        }
        return saved
    }

    func saveIssue(context: ModelContext) -> Bool {
        guard canSaveIssue else { return false }
        let issue = Issue(
            title: issueTitle.trimmingCharacters(in: .whitespaces),
            detail: issueDetail.isEmpty ? nil : issueDetail,
            notifyAt: issueHasNotify ? issueNotifyAt : nil
        )
        context.insert(issue)
        let saved = save(context: context)
        if saved, issueHasNotify {
            NotificationService.shared.scheduleIssueNotification(for: issue)
        }
        return saved
    }

    func resetCurrentTab() {
        switch selectedTab {
        case .task:
            taskTitle = ""
            taskDetail = ""
            taskDate = .now
            taskPriority = .medium
        case .schedule:
            scheduleTitle = ""
            scheduleStartTime = .now
            scheduleEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            scheduleLocation = ""
        case .issue:
            issueTitle = ""
            issueDetail = ""
            issueHasNotify = false
            issueNotifyAt = nil
        }
    }

    private func save(context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            logger.error("저장 실패: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return false
        }
    }
}
