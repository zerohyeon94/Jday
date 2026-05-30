import SwiftUI

struct ContentView: View {
    var body: some View {
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
