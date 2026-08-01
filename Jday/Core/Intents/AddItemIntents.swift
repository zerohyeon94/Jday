import AppIntents
import SwiftData
import WidgetKit
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "AppIntents")

/// Siri·단축어로 이슈를 빠르게 추가한다. 예: "Jday 이슈 추가해줘"
struct AddIssueIntent: AppIntent {
    static var title: LocalizedStringResource = "이슈 추가"
    static var description = IntentDescription("Jday에 새 이슈를 추가합니다.")

    @Parameter(title: "이슈 내용", requestValueDialog: "어떤 이슈를 추가할까요?")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("이슈 \(\.$text) 추가")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "추가할 이슈 내용을 알려주세요.")
        }
        guard let container = IntentStore.container else {
            logger.error("인텐트 저장소 사용 불가")
            throw AppIntentError.storeUnavailable
        }
        let context = ModelContext(container)
        context.insert(Issue(title: trimmed, workspace: IntentStore.activeWorkspace))
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "이슈를 추가했어요: \(trimmed)")
    }
}

/// Siri·단축어로 오늘 할 일을 빠르게 추가한다. 예: "Jday 할 일 추가해줘"
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "할 일 추가"
    static var description = IntentDescription("Jday에 오늘 할 일을 추가합니다.")

    @Parameter(title: "할 일 내용", requestValueDialog: "어떤 할 일을 추가할까요?")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("할 일 \(\.$text) 추가")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "추가할 할 일 내용을 알려주세요.")
        }
        guard let container = IntentStore.container else {
            logger.error("인텐트 저장소 사용 불가")
            throw AppIntentError.storeUnavailable
        }
        let context = ModelContext(container)
        context.insert(DailyTask(title: trimmed, date: .now, workspace: IntentStore.activeWorkspace))
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "할 일을 추가했어요: \(trimmed)")
    }
}

enum AppIntentError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable: "저장소에 접근할 수 없어 추가하지 못했어요."
        }
    }
}

/// Siri에 노출할 앱 단축어 모음. 문구에는 앱 이름 토큰(`.applicationName`)이 반드시 포함돼야 한다.
struct JdayAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddIssueIntent(),
            phrases: [
                "\(.applicationName)에 이슈 추가",
                "\(.applicationName) 이슈 추가해줘",
                "\(.applicationName)에서 이슈 추가"
            ],
            shortTitle: "이슈 추가",
            systemImageName: "exclamationmark.triangle"
        )
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "\(.applicationName)에 할 일 추가",
                "\(.applicationName) 할 일 추가해줘",
                "\(.applicationName)에서 할 일 추가"
            ],
            shortTitle: "할 일 추가",
            systemImageName: "checklist"
        )
    }
}
