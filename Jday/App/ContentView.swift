import SwiftUI

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue

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
        macOSRootView()
        #else
        iOSRootView()
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewHelpers.makeContainer())
}
