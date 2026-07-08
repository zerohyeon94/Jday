import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "App")

@main
struct JdayApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self])

        #if DEBUG
        if CommandLine.arguments.contains("-seedPreviewData") {
            container = MainActor.assumeIsolated {
                PreviewHelpers.makeContainer()
            }
            return
        }
        #endif

        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        var storageMode = CloudSyncStatus.StorageMode.cloudKit
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // CloudKit 사용 불가 시 로컬 전용으로 폴백
            logger.error("CloudKit 컨테이너 생성 실패: \(error.localizedDescription)")
            let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            do {
                container = try ModelContainer(for: schema, configurations: localConfig)
                storageMode = .localOnly
            } catch {
                logger.fault("로컬 SwiftData 컨테이너 생성 실패: \(error.localizedDescription)")
                assertionFailure("Failed to create local SwiftData container: \(error)")
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                container = try! ModelContainer(for: schema, configurations: memoryConfig)
                storageMode = .inMemory
            }
        }

        let resolvedMode = storageMode
        MainActor.assumeIsolated {
            CloudSyncStatus.shared.recordStorageMode(resolvedMode)
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
