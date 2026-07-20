import EventKit
import SwiftUI
import SwiftData
import Observation
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "EventKit")

/// Apple 캘린더 이벤트의 읽기 전용 스냅샷. EKEvent를 뷰로 직접 넘기지 않고 값 타입으로 변환한다.
struct ExternalEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: Color
    let location: String?

    /// 이벤트 기간이 해당 날짜와 겹치는지 판정 (Schedule.occurs(on:)과 동일 기준).
    func occurs(on date: Date) -> Bool {
        startTime < date.endOfDay && endTime > date.startOfDay
    }

    var isPast: Bool {
        endTime < .now
    }
}

/// Apple 캘린더(EventKit) 읽기 전용 연동 — 1단계.
/// 쓰기(내보내기)·미리 알림 연동은 이후 단계에서 확장한다.
@MainActor
@Observable
final class EventKitService {
    static let shared = EventKitService()

    /// 설정 키 — App Group defaults에 저장해 이후 위젯에서도 읽을 수 있게 한다.
    static let enabledKey = "appleCalendarEnabled"
    static let selectedCalendarsKey = "appleCalendarSelectedIDs"
    static let exportEnabledKey = "appleCalendarExportEnabled"
    static let exportCalendarIDKey = "appleCalendarExportCalendarID"
    /// 내보내기 전용 캘린더 이름
    static let exportCalendarTitle = "Jday"

    private let store = EKEventStore()
    private(set) var authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    /// 캘린더 DB 변경·설정 변경 시 증가 — 뷰가 이 값을 관찰해 다시 조회한다.
    private(set) var changeCount = 0

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

    /// 전체 접근 권한 요청. 이미 거부된 상태면 시스템 팝업 없이 false가 반환된다.
    func requestFullAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            changeCount += 1
            return granted
        } catch {
            logger.error("캘린더 권한 요청 실패: \(error.localizedDescription)")
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    // MARK: - 캘린더 선택

    struct CalendarInfo: Identifiable, Hashable {
        let id: String
        let title: String
        let color: Color
    }

    var availableCalendars: [CalendarInfo] {
        guard hasFullAccess else { return [] }
        return displayCandidateCalendars()
            .map { CalendarInfo(id: $0.calendarIdentifier, title: $0.title, color: Self.color(of: $0)) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// 표시 대상 후보 캘린더 — Jday가 내보낸 전용 캘린더는 중복 표시를 막기 위해 제외.
    private func displayCandidateCalendars() -> [EKCalendar] {
        let exportID = AppGroup.defaults.string(forKey: Self.exportCalendarIDKey)
        return store.calendars(for: .event).filter { $0.calendarIdentifier != exportID }
    }

    /// 표시할 캘린더 ID 목록. nil = 전체 표시(기본값).
    var selectedCalendarIDs: Set<String>? {
        get {
            guard let stored = AppGroup.defaults.array(forKey: Self.selectedCalendarsKey) as? [String] else { return nil }
            return Set(stored)
        }
        set {
            if let newValue {
                AppGroup.defaults.set(Array(newValue), forKey: Self.selectedCalendarsKey)
            } else {
                AppGroup.defaults.removeObject(forKey: Self.selectedCalendarsKey)
            }
            changeCount += 1
        }
    }

    // MARK: - 이벤트 조회

    /// 기간 내 이벤트를 시작 시각순으로 반환. 권한이 없으면 빈 배열.
    func events(from start: Date, to end: Date) -> [ExternalEvent] {
        logger.debug("이벤트 조회 요청 — 권한 상태 \(self.authorizationStatus.rawValue)")
        guard hasFullAccess else { return [] }

        var candidates = displayCandidateCalendars()
        if let selected = selectedCalendarIDs {
            candidates = candidates.filter { selected.contains($0.calendarIdentifier) }
        }
        // 빈 배열을 predicate에 넘기면 전체 조회가 되므로 명시적으로 빈 결과 반환
        guard !candidates.isEmpty else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: candidates)
        let matched = store.events(matching: predicate)
        logger.debug("이벤트 조회 결과 \(matched.count)건")
        return matched
            .compactMap { event -> ExternalEvent? in
                guard let startTime = event.startDate, let endTime = event.endDate else { return nil }
                return ExternalEvent(
                    id: "\(event.eventIdentifier ?? UUID().uuidString)-\(startTime.timeIntervalSince1970)",
                    title: event.title ?? String(localized: "제목 없음"),
                    startTime: startTime,
                    endTime: endTime,
                    isAllDay: event.isAllDay,
                    calendarTitle: event.calendar?.title ?? "",
                    calendarColor: Self.color(of: event.calendar),
                    location: event.location
                )
            }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - 내보내기 (2단계)

    var isExportEnabled: Bool {
        AppGroup.defaults.bool(forKey: Self.exportEnabledKey)
    }

    /// 내보내기 전용 "Jday" 캘린더를 찾거나 생성한다.
    /// iCloud(CalDAV) 소스를 우선 사용해 다른 기기의 Apple 캘린더에도 동기화되게 한다.
    func exportCalendar(createIfNeeded: Bool) -> EKCalendar? {
        guard hasFullAccess else { return nil }

        if let id = AppGroup.defaults.string(forKey: Self.exportCalendarIDKey),
           let calendar = store.calendar(withIdentifier: id) {
            return calendar
        }
        // 재설치 등으로 저장된 ID가 유실된 경우 이름으로 재발견
        if let existing = store.calendars(for: .event).first(where: { $0.title == Self.exportCalendarTitle }) {
            AppGroup.defaults.set(existing.calendarIdentifier, forKey: Self.exportCalendarIDKey)
            return existing
        }
        guard createIfNeeded else { return nil }

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = Self.exportCalendarTitle
        #if os(iOS)
        calendar.cgColor = UIColor.systemBlue.cgColor
        #endif
        let source = store.sources.first { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains("icloud") }
            ?? store.defaultCalendarForNewEvents?.source
            ?? store.sources.first { $0.sourceType == .local }
        guard let source else {
            logger.error("내보내기 캘린더 생성 실패: 사용 가능한 캘린더 소스 없음")
            return nil
        }
        calendar.source = source
        do {
            try store.saveCalendar(calendar, commit: true)
            AppGroup.defaults.set(calendar.calendarIdentifier, forKey: Self.exportCalendarIDKey)
            logger.info("내보내기 캘린더 'Jday' 생성 완료")
            return calendar
        } catch {
            logger.error("내보내기 캘린더 생성 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// Jday 일정을 Apple 캘린더 이벤트로 생성/갱신하고 외부 식별자를 기록한다.
    /// 호출 후 ModelContext 저장은 호출부 책임.
    @discardableResult
    func syncExport(for schedule: Schedule) -> Bool {
        guard isExportEnabled, hasFullAccess,
              let calendar = exportCalendar(createIfNeeded: true) else { return false }

        let event: EKEvent
        if let existing = exportedEvent(for: schedule) {
            event = existing
        } else {
            event = EKEvent(eventStore: store)
            event.calendar = calendar
        }
        event.title = schedule.title
        event.startDate = schedule.startTime
        event.endDate = schedule.endTime
        event.location = schedule.location
        do {
            try store.save(event, span: .thisEvent, commit: true)
            schedule.exportedEventID = event.calendarItemExternalIdentifier ?? event.eventIdentifier
            return true
        } catch {
            logger.error("일정 내보내기 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 내보낸 이벤트를 Apple 캘린더에서 제거한다 (일정 삭제 시).
    func removeExport(for schedule: Schedule) {
        guard hasFullAccess, let event = exportedEvent(for: schedule) else { return }
        do {
            try store.remove(event, span: .thisEvent, commit: true)
            schedule.exportedEventID = nil
        } catch {
            logger.error("내보낸 이벤트 제거 실패: \(error.localizedDescription)")
        }
    }

    /// 내보내기를 켠 시점의 일괄 내보내기 — 아직 끝나지 않은 일정만 대상.
    func exportFutureSchedules(_ schedules: [Schedule]) {
        for schedule in schedules where schedule.endTime >= .now {
            syncExport(for: schedule)
        }
    }

    // MARK: - 양방향 동기화 (3단계)

    /// 역동기화 대상 기간 — 이 범위 밖 일정은 삭제 판정에서 제외해 오삭제를 방지한다.
    private var syncBackInterval: (start: Date, end: Date) {
        let now = Date.now
        let start = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let end = Calendar.current.date(byAdding: .year, value: 2, to: now) ?? now
        return (start, end)
    }

    /// Apple 캘린더의 'Jday' 캘린더에서 일어난 변경(수정·삭제·직접 추가)을 Jday로 역반영한다.
    /// 충돌은 수정 시각 비교로 최신 쪽을 채택한다 (Apple이 최신이면 가져오고, Jday가 최신이면 다시 내보낸다).
    @discardableResult
    func syncBack(context: ModelContext) -> Bool {
        guard isExportEnabled, hasFullAccess else { return false }

        let schedules = (try? context.fetch(FetchDescriptor<Schedule>())) ?? []

        guard let calendar = exportCalendar(createIfNeeded: false) else {
            // 사용자가 'Jday' 캘린더 자체를 삭제한 경우 — 일정은 보존하고 내보내기만 중단
            if AppGroup.defaults.string(forKey: Self.exportCalendarIDKey) != nil {
                AppGroup.defaults.removeObject(forKey: Self.exportCalendarIDKey)
                AppGroup.defaults.set(false, forKey: Self.exportEnabledKey)
                for schedule in schedules {
                    schedule.exportedEventID = nil
                }
                try? context.save()
                logger.notice("'Jday' 캘린더가 삭제되어 내보내기를 중단함 (일정은 보존)")
            }
            return false
        }

        // 같은 이벤트에 연결된 일정이 여럿이면(여러 기기에서 동시에 가져온 경우 등)
        // 가장 먼저 만들어진 것만 남기고 정리한다.
        var exportedByID: [String: Schedule] = [:]
        var duplicatesRemoved = false
        for schedule in schedules.sorted(by: { $0.createdAt < $1.createdAt }) {
            guard let id = schedule.exportedEventID else { continue }
            if exportedByID[id] == nil {
                exportedByID[id] = schedule
            } else {
                NotificationService.shared.cancelScheduleNotification(for: schedule)
                context.delete(schedule)
                duplicatesRemoved = true
            }
        }
        if duplicatesRemoved {
            logger.notice("중복 연결된 일정을 정리함")
        }

        let interval = syncBackInterval
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: [calendar])
        let events = store.events(matching: predicate)

        var seenIDs = Set<String>()
        var changed = duplicatesRemoved

        for event in events {
            guard let externalID = event.calendarItemExternalIdentifier,
                  !seenIDs.contains(externalID),   // 반복 일정 전개 중복 방지
                  let startTime = event.startDate, let endTime = event.endDate else { continue }
            seenIDs.insert(externalID)

            if let schedule = exportedByID[externalID] {
                let differs = schedule.title != (event.title ?? "")
                    || schedule.startTime != startTime
                    || schedule.endTime != endTime
                    || schedule.location != event.location
                guard differs else { continue }

                if let modified = event.lastModifiedDate, modified > schedule.updatedAt {
                    // Apple 캘린더 쪽이 최신 → 가져오기
                    schedule.title = event.title ?? schedule.title
                    schedule.startTime = startTime
                    schedule.endTime = endTime
                    schedule.location = event.location
                    schedule.updatedAt = .now
                    NotificationService.shared.scheduleScheduleNotification(for: schedule)
                    changed = true
                } else {
                    // Jday 쪽이 최신 → 다시 내보내기
                    syncExport(for: schedule)
                }
            } else {
                // Apple 캘린더에서 직접 추가한 이벤트 → Jday 일정으로 가져오기
                let imported = Schedule(
                    title: event.title ?? String(localized: "제목 없음"),
                    startTime: startTime,
                    endTime: endTime,
                    location: event.location
                )
                imported.exportedEventID = externalID
                context.insert(imported)
                NotificationService.shared.scheduleScheduleNotification(for: imported)
                changed = true
            }
        }

        // Apple 캘린더에서 삭제된 이벤트 → Jday 일정도 삭제 (조회 범위 안의 일정만)
        for (id, schedule) in exportedByID where !seenIDs.contains(id) {
            guard schedule.startTime >= interval.start, schedule.startTime <= interval.end else { continue }
            NotificationService.shared.cancelScheduleNotification(for: schedule)
            context.delete(schedule)
            changed = true
        }

        if changed {
            try? context.save()
            logger.info("역동기화 완료 — 변경 반영됨")
        }
        return changed
    }

    private func exportedEvent(for schedule: Schedule) -> EKEvent? {
        guard let id = schedule.exportedEventID else { return nil }
        // externalIdentifier 우선(기기 간 안정적), eventIdentifier 폴백
        if let item = store.calendarItems(withExternalIdentifier: id).first(where: { $0 is EKEvent }) as? EKEvent {
            return item
        }
        return store.event(withIdentifier: id)
    }

    #if DEBUG
    /// 역동기화 검증용 — 내보낸 이벤트를 Apple 캘린더에서 수정·추가한 상황을 재현하고 syncBack을 실행한다 (`-seedSyncBackTest`).
    func runSyncBackTestSeed(container: ModelContainer) async {
        AppGroup.defaults.set(true, forKey: Self.exportEnabledKey)
        guard await requestFullAccess(), let calendar = exportCalendar(createIfNeeded: false) else {
            logger.error("역동기화 테스트: 권한 또는 'Jday' 캘린더 없음 — 먼저 -seedExportTest 실행 필요")
            return
        }
        let context = container.mainContext

        // 1) 내보낸 이벤트를 Apple 캘린더에서 수정한 상황 재현 (제목 변경)
        let predicate = store.predicateForEvents(withStart: Date.now.startOfDay, end: Date.now.endOfDay, calendars: [calendar])
        if let event = store.events(matching: predicate).first {
            event.title = "수정된 테스트 일정 (Apple)"
            try? store.save(event, span: .thisEvent, commit: true)
        }

        // 2) Apple 캘린더에서 'Jday' 캘린더에 직접 새 이벤트를 추가한 상황 재현
        let newEvent = EKEvent(eventStore: store)
        newEvent.calendar = calendar
        newEvent.title = "Apple에서 추가한 일정"
        newEvent.startDate = .now
        newEvent.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
        try? store.save(newEvent, span: .thisEvent, commit: true)

        // 3) 역동기화 실행
        let changed = syncBack(context: context)
        logger.info("역동기화 테스트 결과: changed=\(changed)")
    }

    /// 내보내기 검증용 — 내보내기를 켜고 테스트 일정을 만들어 Apple 캘린더 반영까지 확인한다 (`-seedExportTest` 실행 인자).
    func runExportTestSeed(container: ModelContainer) async {
        AppGroup.defaults.set(true, forKey: Self.exportEnabledKey)
        guard await requestFullAccess() else {
            logger.error("내보내기 테스트: 권한 없음 (상태 \(self.authorizationStatus.rawValue))")
            return
        }
        let context = container.mainContext
        let schedule = Schedule(
            title: "내보내기 테스트 일정",
            startTime: .now,
            endTime: Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now,
            location: "시뮬레이터"
        )
        context.insert(schedule)
        try? context.save()
        let exported = syncExport(for: schedule)
        try? context.save()
        logger.info("내보내기 테스트 결과: \(exported ? "성공" : "실패"), externalID=\(schedule.exportedEventID ?? "nil")")
    }

    /// UI 검증용 — 표시 설정을 켜고 기본 캘린더에 오늘 이벤트를 1개 추가한다 (`-seedAppleCalendarEvent` 실행 인자).
    func seedTodayEventForTesting() async {
        AppGroup.defaults.set(true, forKey: Self.enabledKey)
        guard await requestFullAccess() else {
            logger.error("시드 실패: 캘린더 전체 접근 권한 없음 (상태 \(self.authorizationStatus.rawValue))")
            return
        }
        let event = EKEvent(eventStore: store)
        event.title = "테스트 이벤트 (Apple 캘린더)"
        // 자정 직전 실행 시에도 오늘 범위에 들어오도록 현재 시각부터 30분짜리 이벤트로 생성
        event.startDate = .now
        event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
        event.location = "시뮬레이터"
        event.calendar = store.defaultCalendarForNewEvents
        do {
            try store.save(event, span: .thisEvent)
        } catch {
            logger.error("테스트 이벤트 저장 실패: \(error.localizedDescription)")
        }
    }
    #endif

    private static func color(of calendar: EKCalendar?) -> Color {
        #if os(macOS)
        guard let nsColor = calendar?.color else { return .secondary }
        return Color(nsColor: nsColor)
        #else
        guard let cgColor = calendar?.cgColor else { return .secondary }
        return Color(cgColor: cgColor)
        #endif
    }
}
