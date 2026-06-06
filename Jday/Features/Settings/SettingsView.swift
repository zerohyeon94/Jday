import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("emailSummaryEnabled") private var emailSummaryEnabled = false
    @AppStorage("notifyMinutesBefore") private var notifyMinutesBefore = 30
    @AppStorage("startTab") private var startTab = "home"
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = false
    @AppStorage("autoHideCompleted") private var autoHideCompleted = true
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage("workspaceSeparationEnabled") private var workspaceSeparationEnabled = false
    @AppStorage("activeWorkspace") private var activeWorkspaceRaw = Workspace.personal.rawValue

    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showResetAlert = false

    var body: some View {
        Form {
            notificationSection
            generalSection
            workspaceSection
            dataSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.appBackground)
        .navigationTitle("설정")
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task { await checkNotificationStatus() }
        .alert("모든 데이터 삭제", isPresented: $showResetAlert) {
            Button("삭제", role: .destructive) { deleteAllData() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("모든 할 일·일정·이슈가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
    }

    private var notificationSection: some View {
        Section("알림") {
            if notificationAuthStatus == .denied {
                Label("알림 권한이 필요합니다", systemImage: "bell.slash")
                    .foregroundStyle(.orange)
                Button("시스템 설정 열기") { openSystemSettings() }
            }

            toggleRow(
                title: "푸시 알림",
                subtitle: "이슈·일정 리마인더 받기",
                isOn: $notificationsEnabled
            )
            .disabled(notificationAuthStatus == .denied)

            toggleRow(
                title: "이메일 요약",
                subtitle: "매일 아침 요약 메일",
                isOn: $emailSummaryEnabled
            )

            if notificationsEnabled {
                Picker("기본 알림 시간", selection: $notifyMinutesBefore) {
                    ForEach([5, 10, 15, 30, 60], id: \.self) { Text("\($0)분 전").tag($0) }
                }
            }
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    private var generalSection: some View {
        Section("일반") {
            Picker(selection: appearanceBinding) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon).tag(mode)
                }
            } label: {
                Text("화면 모드")
            }

            Picker("시작 화면", selection: $startTab) {
                Text("홈").tag("home")
                Text("캘린더").tag("calendar")
            }

            Picker("한 주 시작 요일", selection: $weekStartsOnMonday) {
                Text("일요일").tag(false)
                Text("월요일").tag(true)
            }

            toggleRow(
                title: "완료 항목 자동 숨김",
                subtitle: "체크 후 24시간 뒤 숨김",
                isOn: $autoHideCompleted
            )
        }
    }

    private var workspaceSection: some View {
        Section {
            toggleRow(
                title: "회사/개인 공간 분리",
                subtitle: "할 일·일정·이슈를 개인/회사로 나눠 관리",
                isOn: $workspaceSeparationEnabled
            )

            if workspaceSeparationEnabled {
                LabeledContent("현재 공간") {
                    Text((Workspace(rawValue: activeWorkspaceRaw) ?? .personal).label)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("작업 공간")
        } footer: {
            if workspaceSeparationEnabled {
                Text("개인/회사는 홈 화면 상단 토글로 전환합니다. 각 공간의 항목은 해당 공간에서만 보입니다. 단, 데이터 저장소가 완전히 분리되는 것은 아니며 모든 항목은 같은 iCloud에 동기화됩니다. 회사 기기 정책(MDM·Managed Apple Account)에 따라 개인 iCloud 동기화가 제한될 수 있습니다.")
            }
        }
    }

    private var dataSection: some View {
        Section("데이터") {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Text("모든 데이터 삭제")
            }
        }
    }

    private func toggleRow(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func deleteAllData() {
        try? context.delete(model: DailyTask.self)
        try? context.delete(model: Schedule.self)
        try? context.delete(model: Issue.self)
        try? context.save()
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthStatus = settings.authorizationStatus
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: "app-settings:") {
            openURL(url)
        }
        #endif
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
