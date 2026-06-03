import SwiftUI

/// 카드형 리스트(비-List)에서 왼쪽 스와이프로 삭제 버튼을 노출하는 행 래퍼.
/// 내부 콘텐츠의 탭(체크박스·본문 버튼)과 공존하도록 가로 드래그만 가로챈다.
struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0

    private let actionWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton
            content()
                .background(Theme.Colors.card)
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .clipped()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            reset()
            onDelete()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
                .background(Color.red)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(offset < -1 ? 1 : 0)
        .accessibilityLabel("삭제")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                // 수평 이동이 수직보다 클 때만 반응(세로 스크롤과 분리)
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let proposed = startOffset + value.translation.width
                offset = min(0, max(-actionWidth, proposed))
            }
            .onEnded { value in
                withAnimation(.easeOut(duration: 0.2)) {
                    if offset < -actionWidth / 2 {
                        offset = -actionWidth
                        startOffset = -actionWidth
                    } else {
                        reset()
                    }
                }
            }
    }

    private func reset() {
        offset = 0
        startOffset = 0
    }
}
