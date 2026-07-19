import AppIntents
import SwiftData
import WidgetKit
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "Widget")

/// 위젯에서 할 일 완료를 바로 토글하는 AppIntent.
/// 변경은 로컬 저장소에만 기록되고 CloudKit 업로드는 다음 메인 앱 실행 시 반영된다.
struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "할 일 완료 전환"

    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        guard let id = WidgetStore.decodeID(taskID), let container = WidgetStore.container else {
            logger.error("ToggleTaskIntent: 대상 할 일 식별 실패")
            return .result()
        }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<DailyTask>(predicate: #Predicate { $0.persistentModelID == id })
        do {
            guard let task = try context.fetch(descriptor).first else { return .result() }
            task.setDone(!task.isDone)
            try context.save()
        } catch {
            logger.error("ToggleTaskIntent 저장 실패: \(error.localizedDescription)")
        }
        return .result()
    }
}
