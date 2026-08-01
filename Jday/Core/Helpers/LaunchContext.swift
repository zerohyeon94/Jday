import Foundation

/// 앱 실행 시 첫 화면을 요일·공휴일 컨텍스트로 결정한다(노션 기획: Context-Aware UX).
/// 월요일 또는 공휴일 다음날이면 "주간 계획 모드"로 캘린더를 먼저 연다.
enum LaunchContext {
    /// 오늘 첫 화면으로 캘린더(주간 계획 모드)를 열어야 하는지 여부.
    static func shouldOpenCalendar(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        // 월요일 — 주말 뒤 첫 근무일
        if calendar.component(.weekday, from: date) == 2 { return true }
        // 공휴일 다음날 — 어제가 (고정 양력) 공휴일이면 오늘이 계획 시작일
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
           isFixedHoliday(yesterday, calendar: calendar) {
            return true
        }
        return false
    }

    /// 매년 같은 양력 날짜인 대한민국 공휴일(월, 일):
    /// 신정·삼일절·어린이날·현충일·광복절·개천절·한글날·성탄절.
    /// 음력 기반(설날·추석·부처님오신날)과 대체공휴일은 연도별로 바뀌어 데이터 소스가 필요하므로 제외한다.
    /// (추후 EventKit의 공휴일 캘린더나 외부 소스로 확장 가능)
    private static let fixedHolidays: Set<[Int]> = [
        [1, 1],   // 신정
        [3, 1],   // 삼일절
        [5, 5],   // 어린이날
        [6, 6],   // 현충일
        [8, 15],  // 광복절
        [10, 3],  // 개천절
        [10, 9],  // 한글날
        [12, 25]  // 성탄절
    ]

    private static func isFixedHoliday(_ date: Date, calendar: Calendar) -> Bool {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return false }
        return fixedHolidays.contains([month, day])
    }
}
