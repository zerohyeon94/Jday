#if os(macOS)
import SwiftUI
import AppKit

/// DEBUG 전용: 스토어 스크린샷을 위해 창을 고정 크기/위치로 배치한다.
/// `-fixedWindow` 런치 인자가 있을 때만 동작. (SwiftUI Representable로 NSWindow 접근)
struct ScreenshotWindowConfigurator: NSViewRepresentable {
    /// 화면 좌상단 기준 위치(pt)와 크기(pt). screencapture -R 좌표와 동일하게 맞춘다.
    var topLeft: CGPoint = CGPoint(x: 100, y: 100)
    var size: CGSize = CGSize(width: 1440, height: 900)

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        configure(view, attempt: 0)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    /// 창이 attach 될 때까지 잠시 재시도하며 고정 배치한다.
    private func configure(_ view: NSView, attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let window = view.window, let screen = NSScreen.main else {
                if attempt < 30 { configure(view, attempt: attempt + 1) }
                return
            }
            window.isRestorable = false
            window.setFrameAutosaveName("")
            window.styleMask.remove(.fullScreen)
            window.setContentSize(size)
            let cocoaY = screen.frame.height - topLeft.y // 화면 상단 기준 → Cocoa(좌하단 원점)
            window.setFrameTopLeftPoint(NSPoint(x: topLeft.x, y: cocoaY))
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

extension View {
    /// `-fixedWindow` 인자가 있으면 스크린샷용 고정 창 배치를 적용.
    @ViewBuilder
    func screenshotFixedWindowIfNeeded() -> some View {
        #if DEBUG
        if CommandLine.arguments.contains("-fixedWindow") {
            self.background(ScreenshotWindowConfigurator())
        } else {
            self
        }
        #else
        self
        #endif
    }
}
#endif
