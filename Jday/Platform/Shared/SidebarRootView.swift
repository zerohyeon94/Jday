#if os(macOS)
import SwiftUI
import SwiftData

/// macOS 전용 루트 — 사이드바 + 디테일 2단 레이아웃.
/// (iPad는 Platform/iPad/iPadRootView 에서 별도 처리)
struct SidebarRootView: View {
    @State private var selectedItem: SidebarItem? = LaunchContext.shouldOpenCalendar() ? .calendar : .home
    @State private var showQuickAdd = false

    @Query private var issues: [Issue]
    private var unresolvedCount: Int { issues.filter { !$0.isResolved }.count }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
                .toolbar { toolbarContent }
        }
    }

    private var sidebar: some View {
        List(selection: $selectedItem) {
            Section("메뉴") {
                ForEach(SidebarItem.allCases) { item in
                    HStack {
                        Label(item.rawValue, systemImage: item.icon)
                        Spacer()
                        if item == .issue, unresolvedCount > 0 {
                            Text("\(unresolvedCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(item)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: Theme.Spacing.sm) {
                Image("AppLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .accessibilityHidden(true)
                Text("Jday")
                    .font(.headline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(.bar)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
    }

    @ViewBuilder
    private var detail: some View {
        switch selectedItem {
        case .home, .none: MacHomeView()
        case .calendar: MacCalendarView()
        case .issue: MacIssueView()
        case .settings: SettingsView()
        }
    }

    /// 현재 화면에 맞는 빠른 추가 기본 탭. 홈→할일, 캘린더→일정, 이슈→이슈.
    private var quickAddInitialTab: QuickAddTab {
        switch selectedItem {
        case .calendar: .schedule
        case .issue: .issue
        default: .task
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showQuickAdd = true
            } label: {
                Label("빠른 추가", systemImage: "plus")
            }
            .popover(isPresented: $showQuickAdd, arrowEdge: .top) {
                QuickAddView(initialTab: quickAddInitialTab)
                    .frame(width: 360)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    SidebarRootView()
        .modelContainer(PreviewHelpers.makeContainer())
}
#endif
