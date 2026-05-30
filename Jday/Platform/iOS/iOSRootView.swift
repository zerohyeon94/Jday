import SwiftUI

enum Tab: String {
    case home
    case calendar
    case quickAdd
    case issue
    case settings
}

struct iOSRootView: View {
    @State private var selectedTab: Tab = defaultTab
    @State private var showQuickAdd = false

    static var defaultTab: Tab {
        Calendar.current.component(.weekday, from: .now) == 2 ? .calendar : .home
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(String(localized: "홈"), systemImage: "house")
                }
                .tag(Tab.home)

            CalendarView()
                .tabItem {
                    Label(String(localized: "캘린더"), systemImage: "calendar")
                }
                .tag(Tab.calendar)

            Color.clear
                .tabItem {
                    Label(String(localized: "추가"), systemImage: "plus.circle.fill")
                }
                .tag(Tab.quickAdd)

            IssueListView()
                .tabItem {
                    Label(String(localized: "이슈"), systemImage: "exclamationmark.bubble")
                }
                .tag(Tab.issue)

            SettingsView()
                .tabItem {
                    Label(String(localized: "설정"), systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .quickAdd {
                showQuickAdd = true
                selectedTab = .home
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
        }
    }
}

#Preview {
    iOSRootView()
        .modelContainer(PreviewHelpers.makeContainer())
}
