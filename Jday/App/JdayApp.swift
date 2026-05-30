import SwiftUI
import SwiftData

@main
struct JdayApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self])

        #if DEBUG
        // UI 검증용 인메모리 시드 데이터
        if CommandLine.arguments.contains("-seedPreviewData") {
            container = MainActor.assumeIsolated { PreviewHelpers.makeContainer() }
            return
        }
        #endif

        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // CloudKit 사용 불가 시 로컬 전용으로 폴백
            let localConfig = ModelConfiguration(schema: schema)
            container = try! ModelContainer(for: schema, configurations: localConfig)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
