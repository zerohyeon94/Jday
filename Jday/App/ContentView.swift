import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @Environment(\.modelContext) private var modelContext

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        rootView
            .preferredColorScheme(appearanceMode.colorScheme)
            .task { seedPersistentDemoIfRequested() }
    }

    private func seedPersistentDemoIfRequested() {
        #if DEBUG
        if CommandLine.arguments.contains("-seedPersistentDemo") {
            PreviewHelpers.seedPersistentDemo(into: modelContext)
        }
        if CommandLine.arguments.contains("-seedPersistentDemo")
            || CommandLine.arguments.contains("-dumpCounts") {
            let tasks = (try? modelContext.fetchCount(FetchDescriptor<DailyTask>())) ?? -1
            let schedules = (try? modelContext.fetchCount(FetchDescriptor<Schedule>())) ?? -1
            let issues = (try? modelContext.fetchCount(FetchDescriptor<Issue>())) ?? -1
            let msg = "tasks=\(tasks) schedules=\(schedules) issues=\(issues)\n"
            try? msg.write(toFile: "/tmp/jday_seed_result.txt", atomically: true, encoding: .utf8)
        }
        #endif
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(macOS)
        macOSRootView()
            .screenshotFixedWindowIfNeeded()
        #else
        iOSRootView()
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewHelpers.makeContainer())
}
