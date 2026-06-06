#if os(iOS)
import SwiftUI
import SwiftData

/// iPad 전용 루트 — 사이드바 + 디테일 2단 레이아웃.
/// 디테일 콘텐츠 뷰(MacHomeView 등)와 공용 컴포넌트를 재사용하고,
/// "껍데기(사이드바 구성·툴바·빠른추가 배치)"만 iPad에 맞게 둔다.
/// → 여기만 고치면 iPhone(iOSRootView)·macOS(SidebarRootView)에 영향 없이 iPad만 바뀐다.
struct iPadRootView: View {
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
                .navigationBarTitleDisplayMode(.inline)
                // iPad: 빠른 추가를 화면 중앙 폼시트로 표시
                .sheet(isPresented: $showQuickAdd) {
                    QuickAddView(initialTab: quickAddInitialTab)
                }
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
        .listStyle(.sidebar)
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
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
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
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("빠른 추가")
                }
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.brand)
        }
    }
}

#Preview {
    iPadRootView()
        .modelContainer(PreviewHelpers.makeContainer())
}
#endif
