import SwiftUI
import SwiftData

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

/// 사이드바 + 디테일 2단 레이아웃. 넓은 화면(macOS · iPad)에서 사용한다.
struct SidebarRootView: View {
    @State private var selectedItem: SidebarItem? = .home
    @State private var showQuickAdd = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @Query private var issues: [Issue]
    private var unresolvedCount: Int { issues.filter { !$0.isResolved }.count }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detail
                .toolbar { toolbarContent }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
        .navigationSplitViewStyle(.balanced)
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
        #if os(iOS)
        .listStyle(.sidebar)
        #endif
        // 로고 헤더를 상단에 고정(스크롤·안전영역과 분리)하고 배경을 맞춰 잘림/이질감 제거
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
