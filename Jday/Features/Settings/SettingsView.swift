import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifyMinutesBefore") private var notifyMinutesBefore = 30
    @AppStorage("startTab") private var startTab = "home"
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = false
    @AppStorage("autoHideCompleted") private var autoHideCompleted = false

    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                calendarSection
                displaySection
            }
            .navigationTitle(String(localized: "설정"))
            .task { await checkNotificationStatus() }
        }
    }

    private var notificationSection: some View {
        Section(String(localized: "알림")) {
            if notificationAuthStatus == .denied {
                Label(String(localized: "알림 권한이 필요합니다"), systemImage: "bell.slash")
                    .foregroundStyle(.orange)

                Button(String(localized: "시스템 설정 열기")) {
                    openSystemSettings()
                }
            }

            Toggle(String(localized: "푸시 알림"), isOn: $notificationsEnabled)
                .disabled(notificationAuthStatus == .denied)

            if notificationsEnabled {
                Stepper(
                    String(localized: "\(notifyMinutesBefore)분 전 알림"),
                    value: $notifyMinutesBefore,
                    in: 5...60,
                    step: 5
                )
            }
        }
    }

    private var calendarSection: some View {
        Section(String(localized: "캘린더")) {
            Toggle(String(localized: "한 주를 월요일부터 시작"), isOn: $weekStartsOnMonday)
        }
    }

    private var displaySection: some View {
        Section(String(localized: "화면")) {
            Picker(String(localized: "시작 화면"), selection: $startTab) {
                Text("홈").tag("home")
                Text("캘린더").tag("calendar")
            }

            Toggle(String(localized: "완료 항목 자동 숨김"), isOn: $autoHideCompleted)
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthStatus = settings.authorizationStatus
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

#Preview {
    SettingsView()
}
