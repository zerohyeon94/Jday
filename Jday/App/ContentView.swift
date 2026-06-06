import SwiftUI

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        rootView
            .preferredColorScheme(appearanceMode.colorScheme)
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(macOS)
        SidebarRootView()
        #else
        // 넓은 화면(iPad)은 iPad 전용 레이아웃, iPhone(컴팩트)은 탭바 레이아웃
        if horizontalSizeClass == .regular {
            iPadRootView()
        } else {
            iOSRootView()
        }
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewHelpers.makeContainer())
}
