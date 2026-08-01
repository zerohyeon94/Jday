import SwiftUI
import SwiftData
import OSLog
import WidgetKit
import EventKit

private let logger = Logger(subsystem: "com.j.jday", category: "App")

@main
struct JdayApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self, Retrospective.self])

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
                #if os(iOS)
                // 앱 사용 중 Apple 캘린더가 바뀌면 즉시 역반영
                .task {
                    for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                        EventKitService.shared.syncBack(context: container.mainContext)
                        await ReminderService.shared.syncBack(context: container.mainContext)
                    }
                }
                #endif
                #if DEBUG
                .task {
                    if CommandLine.arguments.contains("-seedAppleCalendarEvent") {
                        await EventKitService.shared.seedTodayEventForTesting()
                    }
                    if CommandLine.arguments.contains("-seedExportTest") {
                        await EventKitService.shared.runExportTestSeed(container: container)
                    }
                    if CommandLine.arguments.contains("-seedSyncBackTest") {
                        await EventKitService.shared.runSyncBackTestSeed(container: container)
                    }
                    if CommandLine.arguments.contains("-seedReminderTest") {
                        await ReminderService.shared.runReminderTestSeed(container: container)
                    }
                }
                #endif
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            #if os(iOS)
            // 앱에서 변경한 데이터를 위젯에 즉시 반영
            if newPhase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
            // 백그라운드 동안 Apple 캘린더·미리 알림에서 바뀐 내용을 역반영
            if newPhase == .active {
                EventKitService.shared.syncBack(context: container.mainContext)
                Task { await ReminderService.shared.syncBack(context: container.mainContext) }
            }
            #endif
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }

        // 메뉴바 위젯 — 오늘 업무 빠른 확인 + 할 일 체크
        MenuBarExtra("Jday", systemImage: "checklist") {
            MenuBarContentView()
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
