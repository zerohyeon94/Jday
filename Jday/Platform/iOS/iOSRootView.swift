import SwiftUI

enum Tab: String {
    case home
    case calendar
    case quickAdd
    case issue
    case settings
}

struct iOSRootView: View {
    @AppStorage("startTab") private var startTab = "home"
    @State private var selectedTab: Tab = iOSRootView.defaultTab
    @State private var previousTab: Tab = iOSRootView.defaultTab
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

                // 중앙 FAB 자리 확보용 placeholder 탭 (간격 균등화)
                Color.clear
                    .tabItem { Text(" ") }
                    .tag(Tab.quickAdd)

                NavigationStack { IssueListView() }
                    .tabItem { Label("이슈", systemImage: "exclamationmark.triangle") }
                    .tag(Tab.issue)

                NavigationStack { SettingsView() }
                    .tabItem { Label("설정", systemImage: "sun.max") }
                    .tag(Tab.settings)
            }
            .tint(Theme.Colors.brand)
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == .quickAdd {
                    showQuickAdd = true
                    selectedTab = oldValue == .quickAdd ? previousTab : oldValue
                } else {
                    previousTab = newValue
                }
            }

            fab
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView(initialTab: quickAddInitialTab)
        }
        .onAppear {
            let initial: Tab = startTab == "calendar" ? .calendar : iOSRootView.defaultTab
            selectedTab = initial
            previousTab = initial
            #if DEBUG
            if let forced = UserDefaults.standard.string(forKey: "forceTab"),
               let tab = Tab(rawValue: forced) {
                selectedTab = tab
                previousTab = tab
            }
            if CommandLine.arguments.contains("-openQuickAdd") {
                showQuickAdd = true
            }
            #endif
        }
    }

    /// 현재 화면에 맞는 빠른 추가 기본 탭. 홈→할일, 캘린더→일정, 이슈→이슈.
    private var quickAddInitialTab: QuickAddTab {
        switch previousTab {
        case .calendar: .schedule
        case .issue: .issue
        default: .task
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
