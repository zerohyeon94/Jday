import SwiftUI
import SwiftData
import OSLog
import WidgetKit

private let logger = Logger(subsystem: "com.j.jday", category: "App")

@main
struct JdayApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

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

        // iOS는 위젯과 저장소를 공유하기 위해 App Group 컨테이너 사용, macOS는 기존 위치 유지
        #if os(iOS)
        AppGroup.migrateDefaultsIfNeeded()
        AppGroup.migrateStoreIfNeeded()
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.id), cloudKitDatabase: .automatic)
        #else
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        #endif
        var storageMode = CloudSyncStatus.StorageMode.cloudKit
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // CloudKit 사용 불가 시 로컬 전용으로 폴백
            logger.error("CloudKit 컨테이너 생성 실패: \(error.localizedDescription)")
            #if os(iOS)
            let localConfig = ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.id), cloudKitDatabase: .none)
            #else
            let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            #endif
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
                #if DEBUG
                .task {
                    if CommandLine.arguments.contains("-seedAppleCalendarEvent") {
                        await EventKitService.shared.seedTodayEventForTesting()
                    }
                }
                #endif
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            // 앱에서 변경한 데이터를 위젯에 즉시 반영
            #if os(iOS)
            if newPhase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
            #endif
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
