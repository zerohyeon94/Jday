import SwiftUI

struct SummaryCardView: View {
    let value: String
    let label: LocalizedStringKey
    var isAccent: Bool = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(isAccent ? Theme.Colors.brand : .primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .cardStyle(padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Text(label)): \(value)")
    }
}

#Preview {
    HStack(spacing: 10) {
        SummaryCardView(value: "3", label: "할 일 남음")
        SummaryCardView(value: "4", label: "오늘 일정")
        SummaryCardView(value: "40%", label: "진행률", isAccent: true)
    }
    .padding()
    .background(Theme.Colors.appBackground)
}
