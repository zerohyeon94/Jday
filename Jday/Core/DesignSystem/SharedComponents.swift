import SwiftUI

// MARK: - Primary filled button (저장 / 모두 오늘로 옮기기 / 해결완료로 표시)

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .fill(Theme.Colors.brand)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1.0) : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Card section header (제목 + 우측 보조 텍스트)

struct CardHeader: View {
    let title: LocalizedStringKey
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Pill segmented picker (전체/미해결/해결완료, 할 일/일정/이슈)

struct PillPicker<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection

                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(isSelected ? Theme.Colors.brand : Theme.Colors.card)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Theme.Colors.cardStroke, lineWidth: isSelected ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

// MARK: - Status badge (미해결 / 해결완료)

struct StatusBadge: View {
    let isResolved: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(isResolved ? Color.gray : Theme.Colors.brand)
                .frame(width: 6, height: 6)
            Text(isResolved ? "해결완료" : "미해결")
                .font(.caption2.weight(.medium))
                .foregroundStyle(isResolved ? .secondary : Theme.Colors.brand)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(isResolved ? Theme.Colors.resolvedBadgeBackground : Theme.Colors.unresolvedBadgeBackground)
        )
        .accessibilityLabel(isResolved ? "해결완료" : "미해결")
    }
}
