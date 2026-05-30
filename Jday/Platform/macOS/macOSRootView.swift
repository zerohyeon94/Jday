import SwiftUI

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
        case .issue: "exclamationmark.bubble"
        case .settings: "gearshape"
        }
    }
}

struct macOSRootView: View {
    @State private var selectedItem: SidebarItem? = .home
    @State private var showQuickAdd = false

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Jday")
        } detail: {
            switch selectedItem {
            case .home, .none: HomeView()
            case .calendar: CalendarView()
            case .issue: IssueListView()
            case .settings: SettingsView()
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showQuickAdd = true
                } label: {
                    Label(String(localized: "빠른 추가"), systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .frame(minWidth: 400, minHeight: 400)
        }
    }
}

#Preview {
    macOSRootView()
        .modelContainer(PreviewHelpers.makeContainer())
}
