import SwiftUI

/// 하단에 잠깐 떠오르는 토스트. 선택적으로 실행 취소 액션 버튼을 포함한다.
struct ToastView: View {
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)

            if let actionTitle, let action {
                Spacer(minLength: Theme.Spacing.md)
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(white: 0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Capsule().fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, Theme.screenPadding)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Theme.Colors.appBackground
        ToastView(message: "할 일을 삭제했어요", actionTitle: "실행 취소", action: {})
            .padding(.bottom, 40)
    }
    .ignoresSafeArea()
}
