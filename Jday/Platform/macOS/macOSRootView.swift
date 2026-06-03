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
        case .settings: "sun.max"
        }
    }
}

struct macOSRootView: View {
    @State private var selectedItem: SidebarItem? = .home
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
        #if DEBUG
        .onAppear {
            if let forced = UserDefaults.standard.string(forKey: "forceTab") {
                switch forced {
                case "calendar": selectedItem = .calendar
                case "issue": selectedItem = .issue
                case "settings": selectedItem = .settings
                default: selectedItem = .home
                }
            }
        }
        #endif
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.lg)

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

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                Circle().fill(Theme.Colors.cardStroke).frame(width: 24, height: 24)
                    .overlay(Image(systemName: "person.fill").font(.caption).foregroundStyle(.secondary))
                Text("김도현").font(.subheadline)
            }
            .padding(Theme.Spacing.md)
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
    macOSRootView()
        .modelContainer(PreviewHelpers.makeContainer())
}
