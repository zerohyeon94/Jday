import Foundation
import SwiftData

/// App Intents(Siri·단축어)에서 앱과 같은 SwiftData 저장소에 접근한다.
/// 위젯의 `WidgetStore`와 같은 방식 — iOS는 App Group, macOS는 기본 위치.
/// CloudKit 업로드는 앱이 담당하므로 인텐트는 로컬(.none)로 쓰고, 앱 실행 시 동기화된다.
enum IntentStore {
    static let container: ModelContainer? = {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self, Retrospective.self])
        #if os(iOS)
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.id), cloudKitDatabase: .none)
        #else
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        #endif
        return try? ModelContainer(for: schema, configurations: config)
    }()

    /// 작업 공간 분리가 켜져 있으면 활성 공간, 아니면 nil(미분류).
    static var activeWorkspace: Workspace? {
        guard AppGroup.defaults.bool(forKey: "workspaceSeparationEnabled") else { return nil }
        return Workspace(rawValue: AppGroup.defaults.string(forKey: "activeWorkspace") ?? "") ?? .personal
    }
}
