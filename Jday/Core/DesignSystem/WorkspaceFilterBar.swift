import SwiftUI

/// 작업 공간 분리가 켜졌을 때 개인 ⇄ 회사를 전환하는 토글(세그먼트).
/// AppStorage("activeWorkspace")를 공유하므로 어느 화면에 두어도 동기화된다.
struct WorkspaceToggle: View {
    @AppStorage("activeWorkspace") private var activeRaw = Workspace.personal.rawValue

    private var binding: Binding<Workspace> {
        Binding(
            get: { Workspace(rawValue: activeRaw) ?? .personal },
            set: { activeRaw = $0.rawValue }
        )
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Workspace.allCases) { ws in
                let isSelected = binding.wrappedValue == ws

                Button {
                    withAnimation(.easeOut(duration: 0.15)) { binding.wrappedValue = ws }
                } label: {
                    Label(ws.label, systemImage: ws.icon)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            Capsule().fill(isSelected ? Theme.Colors.brand : Theme.Colors.card)
                        )
                        .overlay(
                            Capsule().stroke(Theme.Colors.cardStroke, lineWidth: isSelected ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ws.label)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

#Preview {
    WorkspaceToggle()
        .padding()
        .background(Theme.Colors.appBackground)
}
