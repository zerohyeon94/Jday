import Foundation

/// 사이드바(넓은 화면: iPad · macOS) 메뉴 항목. 양 플랫폼 루트 뷰가 공유한다.
enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "홈"
    case calendar = "캘린더"
    case issue = "이슈"
    case settings = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: "house"
        case .calendar: "calendar"
        case .issue: "exclamationmark.triangle"
        case .settings: "gearshape"
        }
    }
}
