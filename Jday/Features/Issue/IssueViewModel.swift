import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "IssueViewModel")

enum IssueFilter: String, CaseIterable {
    case all = "전체"
    case unresolved = "미해결"
    case resolved = "해결완료"
}

@MainActor
final class IssueViewModel: ObservableObject {
    @Published var filter: IssueFilter = .all

    func filteredIssues(_ issues: [Issue]) -> [Issue] {
        switch filter {
        case .all: issues
        case .unresolved: issues.filter { !$0.isResolved }
        case .resolved: issues.filter { $0.isResolved }
        }
    }

    func resolve(_ issue: Issue, context: ModelContext) {
        issue.isResolved = true
        issue.updatedAt = .now
        NotificationService.shared.cancelIssueNotification(for: issue)
        save(context: context)
    }

    func delete(_ issue: Issue, context: ModelContext) {
        NotificationService.shared.cancelIssueNotification(for: issue)
        context.delete(issue)
        save(context: context)
    }

    private func save(context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("저장 실패: \(error.localizedDescription)")
        }
    }
}
