import EventKit
import SwiftUI
import SwiftData
import Observation
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "Reminders")

/// Apple 미리 알림(EKReminder) ↔ 할 일(DailyTask) 양방향 연동.
/// 캘린더 연동([EventKitService])과 권한이 분리되어 있어 별도 스토어·설정으로 관리한다.
@MainActor
@Observable
final class ReminderService {
    static let shared = ReminderService()

    /// 설정 키 — App Group defaults에 저장 (위젯에서도 읽을 수 있게).
    static let syncEnabledKey = "appleRemindersSyncEnabled"
    static let listIDKey = "appleRemindersListID"
    /// 동기화 전용 미리 알림 목록 이름
    static let listTitle = "Jday"

    private let store = EKEventStore()
    private(set) var authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    /// 미리 알림 DB 변경 시 증가 — 뷰가 관찰해 다시 조회한다.
    private(set) var changeCount = 0
    /// 역동기화 진행 여부. 조회 대기 중 다른 트리거가 끼어들어 같은 항목을 두 번 가져오는 것을 막는다.
    private var isSyncingBack = false

    private init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.changeCount += 1 }
        }
    }

    var hasFullAccess: Bool {
        authorizationStatus == .fullAccess
    }

    var isAccessDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var isSyncEnabled: Bool {
        AppGroup.defaults.bool(forKey: Self.syncEnabledKey)
    }

    /// 미리 알림 전체 접근 권한 요청. 이미 거부된 상태면 시스템 팝업 없이 false가 반환된다.
    func requestFullAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToReminders()
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            changeCount += 1
            return granted
        } catch {
            logger.error("미리 알림 권한 요청 실패: \(error.localizedDescription)")
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            return false
        }
    }

    // MARK: - 목록

    /// 동기화 전용 "Jday" 미리 알림 목록을 찾거나 생성한다.
    /// iCloud(CalDAV) 소스를 우선 사용해 다른 기기의 미리 알림에도 동기화되게 한다.
    func reminderList(createIfNeeded: Bool) -> EKCalendar? {
        guard hasFullAccess else { return nil }

        if let id = AppGroup.defaults.string(forKey: Self.listIDKey),
           let list = store.calendar(withIdentifier: id) {
            return list
        }
        // 재설치 등으로 저장된 ID가 유실된 경우 이름으로 재발견
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == Self.listTitle }) {
            AppGroup.defaults.set(existing.calendarIdentifier, forKey: Self.listIDKey)
            return existing
        }
        guard createIfNeeded else { return nil }

        let list = EKCalendar(for: .reminder, eventStore: store)
        list.title = Self.listTitle
        let source = store.sources.first { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud") }
            ?? store.defaultCalendarForNewReminders()?.source
            ?? store.sources.first { $0.sourceType == .local }
        guard let source else {
            logger.error("미리 알림 목록 생성 실패: 사용 가능한 소스 없음")
            return nil
        }
        list.source = source
        do {
            try store.saveCalendar(list, commit: true)
            AppGroup.defaults.set(list.calendarIdentifier, forKey: Self.listIDKey)
            logger.info("미리 알림 목록 'Jday' 생성 완료")
            return list
        } catch {
            logger.error("미리 알림 목록 생성 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 내보내기 (할 일 → 미리 알림)

    /// 할 일을 미리 알림 항목으로 생성/갱신하고 외부 식별자를 기록한다.
    /// 호출 후 ModelContext 저장은 호출부 책임.
    @discardableResult
    func syncExport(for task: DailyTask) async -> Bool {
        guard isSyncEnabled, hasFullAccess,
              let list = reminderList(createIfNeeded: true) else { return false }

        let reminder: EKReminder
        if let existing = exportedReminder(for: task) {
            reminder = existing
        } else {
            reminder = EKReminder(eventStore: store)
            reminder.calendar = list
        }
        apply(task, to: reminder)
        do {
            try store.save(reminder, commit: true)
            task.exportedReminderID = reminder.calendarItemExternalIdentifier ?? reminder.calendarItemIdentifier
            return true
        } catch {
            logger.error("할 일 내보내기 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 내보낸 미리 알림 항목을 제거한다 (할 일 삭제 시).
    func removeExport(for task: DailyTask) async {
        guard let id = task.exportedReminderID else { return }
        await removeExport(reminderID: id)
        task.exportedReminderID = nil
    }

    /// 식별자로 미리 알림 항목을 제거한다.
    /// 할 일을 이미 삭제한 뒤에도 호출할 수 있도록 ID만 받는다.
    func removeExport(reminderID: String) async {
        guard hasFullAccess, let reminder = reminder(withID: reminderID) else { return }
        do {
            try store.remove(reminder, commit: true)
        } catch {
            logger.error("내보낸 미리 알림 제거 실패: \(error.localizedDescription)")
        }
    }

    /// 동기화를 켠 시점의 일괄 내보내기 — 최근 항목만 대상(과거 완료분 대량 유입 방지).
    func exportRecentTasks(_ tasks: [DailyTask]) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        for task in tasks where task.date >= cutoff {
            await syncExport(for: task)
        }
    }

    /// 할 일의 값을 미리 알림 항목에 반영한다.
    private func apply(_ task: DailyTask, to reminder: EKReminder) {
        reminder.title = task.title
        reminder.notes = task.detail
        reminder.priority = Self.reminderPriority(from: task.priority)
        // 마감일은 날짜 단위 — 시각 알람 없이 해당 날짜에 표시되게 한다
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: task.date)
        reminder.isCompleted = task.isDone
        reminder.completionDate = task.completedAt
    }

    // MARK: - 역동기화 (미리 알림 → 할 일)

    /// 미리 알림 'Jday' 목록의 변경(완료 체크·수정·삭제·직접 추가)을 할 일로 역반영한다.
    /// 충돌은 수정 시각 비교로 최신 쪽을 채택한다.
    @discardableResult
    func syncBack(context: ModelContext) async -> Bool {
        guard isSyncEnabled, hasFullAccess else { return false }
        // 조회 대기 중 재진입하면 같은 미리 알림을 중복으로 가져오게 된다.
        // 트리거(앱 활성화·DB 변경)는 반복되므로 건너뛰어도 다음 기회에 반영된다.
        guard !isSyncingBack else { return false }
        isSyncingBack = true
        defer { isSyncingBack = false }

        let tasks = (try? context.fetch(FetchDescriptor<DailyTask>())) ?? []

        guard let list = reminderList(createIfNeeded: false) else {
            // 사용자가 'Jday' 목록 자체를 삭제한 경우 — 할 일은 보존하고 동기화만 중단
            if AppGroup.defaults.string(forKey: Self.listIDKey) != nil {
                AppGroup.defaults.removeObject(forKey: Self.listIDKey)
                AppGroup.defaults.set(false, forKey: Self.syncEnabledKey)
                for task in tasks {
                    task.exportedReminderID = nil
                }
                try? context.save()
                logger.notice("'Jday' 미리 알림 목록이 삭제되어 동기화를 중단함 (할 일은 보존)")
            }
            return false
        }

        // 같은 미리 알림에 연결된 할 일이 여럿이면(여러 기기에서 동시에 가져온 경우 등)
        // 가장 먼저 만들어진 것만 남기고 정리한다.
        var exportedByID: [String: DailyTask] = [:]
        var duplicatesRemoved = false
        for task in tasks.sorted(by: { $0.createdAt < $1.createdAt }) {
            guard let id = task.exportedReminderID else { continue }
            if exportedByID[id] == nil {
                exportedByID[id] = task
            } else {
                context.delete(task)
                duplicatesRemoved = true
            }
        }
        if duplicatesRemoved {
            logger.notice("중복 연결된 할 일을 정리함")
        }

        let reminders = await fetchReminders(in: list)
        // 삭제 판정 범위 — 이 범위 밖 할 일은 제외해 오삭제를 방지
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now

        var seenIDs = Set<String>()
        var changed = duplicatesRemoved

        for reminder in reminders {
            guard let externalID = reminder.calendarItemExternalIdentifier else { continue }
            seenIDs.insert(externalID)

            if let task = exportedByID[externalID] {
                if applyIfNewer(reminder, to: task) {
                    changed = true
                } else if isOutOfSync(reminder, with: task) {
                    // 할 일 쪽이 최신 → 다시 내보내기 (위젯에서 체크한 경우 등)
                    await syncExport(for: task)
                }
            } else {
                // 미리 알림에서 직접 추가한 항목 → 할 일로 가져오기
                let imported = DailyTask(
                    title: reminder.title ?? String(localized: "제목 없음"),
                    detail: reminder.notes,
                    date: Self.dueDate(of: reminder) ?? .now,
                    priority: Self.taskPriority(from: reminder.priority)
                )
                imported.isDone = reminder.isCompleted
                imported.completedAt = reminder.completionDate
                imported.exportedReminderID = externalID
                context.insert(imported)
                changed = true
            }
        }

        // 미리 알림에서 삭제된 항목 → 할 일도 삭제 (최근 항목만)
        for (id, task) in exportedByID where !seenIDs.contains(id) {
            guard task.date >= cutoff else { continue }
            context.delete(task)
            changed = true
        }

        if changed {
            try? context.save()
            logger.info("미리 알림 역동기화 완료 — 변경 반영됨")
        }
        return changed
    }

    /// 미리 알림이 더 최신이면 할 일에 반영하고 true를 반환한다.
    private func applyIfNewer(_ reminder: EKReminder, to task: DailyTask) -> Bool {
        guard isOutOfSync(reminder, with: task),
              let modified = reminder.lastModifiedDate, modified > task.updatedAt else { return false }

        task.title = reminder.title ?? task.title
        task.detail = reminder.notes
        task.priority = Self.taskPriority(from: reminder.priority)
        if let due = Self.dueDate(of: reminder) {
            task.date = due
        }
        task.isDone = reminder.isCompleted
        task.completedAt = reminder.isCompleted ? (reminder.completionDate ?? .now) : nil
        task.updatedAt = .now
        return true
    }

    /// 미리 알림과 할 일의 내용이 서로 다른지 판정.
    private func isOutOfSync(_ reminder: EKReminder, with task: DailyTask) -> Bool {
        if task.title != (reminder.title ?? "") { return true }
        if task.detail != reminder.notes { return true }
        if task.isDone != reminder.isCompleted { return true }
        if task.priority != Self.taskPriority(from: reminder.priority) { return true }
        if let due = Self.dueDate(of: reminder), !due.isSameDay(as: task.date) { return true }
        return false
    }

    private func exportedReminder(for task: DailyTask) -> EKReminder? {
        guard let id = task.exportedReminderID else { return nil }
        return reminder(withID: id)
    }

    /// externalIdentifier 우선(기기 간 안정적), calendarItemIdentifier 폴백.
    private func reminder(withID id: String) -> EKReminder? {
        if let item = store.calendarItems(withExternalIdentifier: id).first(where: { $0 is EKReminder }) as? EKReminder {
            return item
        }
        return store.calendarItem(withIdentifier: id) as? EKReminder
    }

    /// 완료 여부와 무관하게 목록의 모든 항목을 조회한다 (EventKit의 조회 API는 완료 처리 기준이 나뉘어 있음).
    private func fetchReminders(in list: EKCalendar) async -> [EKReminder] {
        let predicate = store.predicateForReminders(in: [list])
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    // MARK: - 값 변환

    /// Jday 우선순위 → EKReminder priority (0 없음, 1~4 높음, 5 보통, 6~9 낮음)
    private static func reminderPriority(from priority: Priority) -> Int {
        switch priority {
        case .high: 1
        case .medium: 5
        case .low: 9
        }
    }

    private static func taskPriority(from value: Int) -> Priority {
        switch value {
        case 1...4: .high
        case 6...9: .low
        default: .medium   // 5(보통)와 0(지정 없음)
        }
    }

    private static func dueDate(of reminder: EKReminder) -> Date? {
        guard let components = reminder.dueDateComponents else { return nil }
        return Calendar.current.date(from: components)
    }

    #if DEBUG
    /// 검증용 — 동기화를 켜고 할 일을 내보낸 뒤, 미리 알림 쪽 완료 체크·직접 추가를 재현해 역동기화까지 확인한다
    /// (`-seedReminderTest` 실행 인자).
    func runReminderTestSeed(container: ModelContainer) async {
        AppGroup.defaults.set(true, forKey: Self.syncEnabledKey)
        guard await requestFullAccess(), let list = reminderList(createIfNeeded: true) else {
            logger.error("미리 알림 테스트: 권한 없음 (상태 \(self.authorizationStatus.rawValue))")
            return
        }
        let context = container.mainContext

        // 1) 할 일 → 미리 알림 내보내기
        let task = DailyTask(title: "미리 알림 테스트 할 일", date: .now, priority: .high)
        context.insert(task)
        try? context.save()
        let exported = await syncExport(for: task)
        try? context.save()
        logger.info("내보내기 결과: \(exported ? "성공" : "실패"), externalID=\(task.exportedReminderID ?? "nil")")

        // 2) 미리 알림 앱에서 완료 체크한 상황 재현
        if let reminder = exportedReminder(for: task) {
            reminder.isCompleted = true
            try? store.save(reminder, commit: true)
        }

        // 3) 미리 알림에서 직접 새 항목을 추가한 상황 재현
        let added = EKReminder(eventStore: store)
        added.calendar = list
        added.title = "미리 알림에서 추가한 할 일"
        added.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        try? store.save(added, commit: true)

        // 4) 역동기화 실행
        let changed = await syncBack(context: context)
        logger.info("역동기화 결과: changed=\(changed), 완료 반영=\(task.isDone)")
    }
    #endif
}
