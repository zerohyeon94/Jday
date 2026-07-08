import Foundation
import CloudKit
import Observation
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "CloudSyncStatus")

/// 앱 실행 시 결정된 저장소 모드와 iCloud 계정 상태를 추적한다.
/// CloudKit 컨테이너 생성이 실패해 로컬 전용으로 폴백한 경우
/// 설정 화면의 "iCloud" 섹션에서 사용자가 상태를 확인할 수 있다.
@MainActor
@Observable
final class CloudSyncStatus {
    static let shared = CloudSyncStatus()

    enum StorageMode {
        /// 정상 — CloudKit 동기화 활성
        case cloudKit
        /// CloudKit 컨테이너 생성 실패 → 로컬 전용 폴백 (기기 간 동기화 안 됨)
        case localOnly
        /// 로컬 저장소도 실패 → 인메모리 폴백 (앱 종료 시 데이터 유실)
        case inMemory
    }

    private(set) var storageMode: StorageMode = .cloudKit
    /// nil이면 아직 확인 전
    private(set) var accountStatus: CKAccountStatus?

    private init() {}

    func recordStorageMode(_ mode: StorageMode) {
        storageMode = mode
        switch mode {
        case .cloudKit:
            logger.info("CloudKit 동기화 모드로 시작")
        case .localOnly:
            logger.error("CloudKit 컨테이너 생성 실패 — 로컬 전용으로 폴백, 기기 간 동기화가 동작하지 않음")
        case .inMemory:
            logger.fault("로컬 저장소 생성 실패 — 인메모리로 폴백, 데이터가 유지되지 않음")
        }
    }

    func refreshAccountStatus() async {
        do {
            accountStatus = try await CKContainer(identifier: "iCloud.com.zerohyeon.jday").accountStatus()
        } catch {
            logger.error("iCloud 계정 상태 확인 실패: \(error.localizedDescription)")
            accountStatus = .couldNotDetermine
        }
    }
}
