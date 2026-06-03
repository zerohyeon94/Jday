import SwiftUI

/// 카드형 리스트(비-List)에서 왼쪽 스와이프로 삭제하는 행 래퍼.
/// - 살짝 밀면: 삭제 버튼이 드러나고, 탭하면 삭제.
/// - 끝까지 밀면(임계값 초과): 손을 떼는 즉시 삭제(미리알림 앱과 동일).
/// 내부 콘텐츠의 탭(체크박스·본문 버튼)과 공존하도록 가로 드래그만 가로챈다.
struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    @State private var rowWidth: CGFloat = 0

    private let actionWidth: CGFloat = 80
    /// 이 거리 이상 밀면 손을 떼는 순간 바로 삭제.
    private var fullSwipeThreshold: CGFloat { max(rowWidth * 0.55, 180) }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteBackground
            content()
                .background(Theme.Colors.card)
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { rowWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in rowWidth = newValue }
            }
        )
        .clipped()
    }

    /// 빨간 배경 + 휴지통. 스와이프하면 우측에서 드러나며, 탭하면 삭제.
    private var deleteBackground: some View {
        Button(role: .destructive) {
            triggerDelete()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.red)
        .opacity(offset < -1 ? 1 : 0)
        .accessibilityLabel("삭제")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                // 수평 이동이 수직보다 클 때만 반응(세로 스크롤과 분리)
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let proposed = startOffset + value.translation.width
                offset = min(0, max(-rowWidth, proposed))
            }
            .onEnded { _ in
                let dragged = -offset
                if dragged >= fullSwipeThreshold {
                    // 끝까지 밀면 즉시 삭제(행은 데이터에서 제거되어 사라짐)
                    triggerDelete()
                } else if dragged >= actionWidth / 2 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = -actionWidth
                        startOffset = -actionWidth
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { reset() }
                }
            }
    }

    private func triggerDelete() {
        reset()
        onDelete()
    }

    private func reset() {
        offset = 0
        startOffset = 0
    }
}
