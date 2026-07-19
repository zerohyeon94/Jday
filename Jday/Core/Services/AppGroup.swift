import Foundation
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "AppGroup")

/// 앱 ↔ 위젯 익스텐션이 공유하는 App Group 컨테이너 정보.
/// iOS에서만 App Group을 사용하고, macOS는 위젯이 없으므로 기존 저장 위치를 유지한다.
enum AppGroup {
    static let id = "group.com.zerohyeon.jday"

    /// 위젯과 공유해야 하는 설정 키 목록 (작업 공간 필터, 주 시작 요일).
    static let sharedDefaultsKeys = ["workspaceSeparationEnabled", "activeWorkspace", "weekStartsOnMonday"]

    private static let defaultsMigratedKey = "appGroupDefaultsMigrated"

    /// iOS는 App Group defaults(위젯과 공유), macOS는 standard.
    static let defaults: UserDefaults = {
        #if os(iOS)
        if let shared = UserDefaults(suiteName: id) {
            return shared
        }
        logger.error("App Group defaults 생성 실패 — standard로 폴백")
        return .standard
        #else
        return .standard
        #endif
    }()

    #if os(iOS)
    /// 기존 standard defaults에 저장된 공유 설정을 App Group defaults로 최초 1회 복사한다.
    static func migrateDefaultsIfNeeded() {
        guard defaults !== UserDefaults.standard, !defaults.bool(forKey: defaultsMigratedKey) else { return }
        for key in sharedDefaultsKeys {
            if defaults.object(forKey: key) == nil, let value = UserDefaults.standard.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }
        defaults.set(true, forKey: defaultsMigratedKey)
        logger.info("공유 설정을 App Group defaults로 이전 완료")
    }

    /// 기존 기본 위치(Application Support)의 SwiftData 저장소를 App Group 컨테이너로 이동한다.
    /// 복사 → 원본 삭제 순서로 진행하고, 실패하면 복사본을 지워 기존 위치를 그대로 사용한다(데이터 보존 우선).
    static func migrateStoreIfNeeded() {
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            logger.error("App Group 컨테이너 URL 확인 실패 — 저장소 이전 건너뜀")
            return
        }
        let destinationDir = groupURL.appending(path: "Library/Application Support")
        let storeSuffixes = ["", "-shm", "-wal"]
        let sourceStore = URL.applicationSupportDirectory.appending(path: "default.store")
        let destinationStore = destinationDir.appending(path: "default.store")

        guard fileManager.fileExists(atPath: sourceStore.path),
              !fileManager.fileExists(atPath: destinationStore.path) else { return }

        var copied: [URL] = []
        do {
            try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            for suffix in storeSuffixes {
                let source = URL.applicationSupportDirectory.appending(path: "default.store" + suffix)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                let destination = destinationDir.appending(path: "default.store" + suffix)
                try fileManager.copyItem(at: source, to: destination)
                copied.append(destination)
            }
            for suffix in storeSuffixes {
                let source = URL.applicationSupportDirectory.appending(path: "default.store" + suffix)
                if fileManager.fileExists(atPath: source.path) {
                    try? fileManager.removeItem(at: source)
                }
            }
            logger.info("SwiftData 저장소를 App Group 컨테이너로 이전 완료")
        } catch {
            logger.error("저장소 이전 실패 — 기존 위치 유지: \(error.localizedDescription)")
            for url in copied {
                try? fileManager.removeItem(at: url)
            }
        }
    }
    #endif
}
