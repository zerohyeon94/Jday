import SwiftUI

enum Tab: String {
    case home
    case calendar
    case issue
    case settings
}

struct iOSRootView: View {
    @AppStorage("startTab") private var startTab = "home"
    @State private var selectedTab: Tab = iOSRootView.defaultTab
    @State private var showQuickAdd = false

    /// 월요일 → 캘린더, 그 외 → 홈
    static var defaultTab: Tab {
        Calendar.current.component(.weekday, from: .now) == 2 ? .calendar : .home
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { HomeView() }
                    .tabItem { Label("홈", systemImage: "house") }
                    .tag(Tab.home)

                NavigationStack { CalendarView() }
                    .tabItem { Label("캘린더", systemImage: "calendar") }
                    .tag(Tab.calendar)

                NavigationStack { IssueListView() }
                    .tabItem { Label("이슈", systemImage: "exclamationmark.triangle") }
                    .tag(Tab.issue)

                NavigationStack { SettingsView() }
                    .tabItem { Label("설정", systemImage: "sun.max") }
                    .tag(Tab.settings)
            }
            .tint(Theme.Colors.brand)

            fab
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .onAppear {
            selectedTab = startTab == "calendar" ? .calendar : iOSRootView.defaultTab
        }
    }

    private var fab: some View {
        Button {
            showQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Theme.Colors.brand))
                .overlay(Circle().stroke(Theme.Colors.appBackground, lineWidth: 4))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .offset(y: -8)
        .accessibilityLabel("빠른 추가")
    }
}

#Preview {
    iOSRootView()
        .modelContainer(PreviewHelpers.makeContainer())
}
