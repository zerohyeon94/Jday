import SwiftUI

/// 홈 화면 "오늘 회고" 카드 — 오늘의 회고를 요약 표시하고, 탭하면 작성·수정 시트를 연다.
struct RetrospectiveCardView: View {
    let retrospective: Retrospective?
    var onTap: () -> Void

    private var trimmedContent: String {
        (retrospective?.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var hasContent: Bool { !trimmedContent.isEmpty }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                CardHeader(title: "오늘 회고", trailing: hasContent ? String(localized: "수정") : nil)

                if hasContent {
                    Text(trimmedContent)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.Colors.brand)
                        Text("오늘 배운 점을 기록해보세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hasContent ? "오늘 회고" : "오늘 회고 없음")
        .accessibilityHint("탭하여 오늘 배운 점을 작성하거나 수정합니다")
    }
}

#Preview("작성됨") {
    RetrospectiveCardView(
        retrospective: Retrospective(content: "코드 리뷰에서 경계 조건 테스트의 중요성을 다시 배웠다."),
        onTap: {}
    )
    .padding()
    .background(Theme.Colors.appBackground)
}

#Preview("빈 상태") {
    RetrospectiveCardView(retrospective: nil, onTap: {})
        .padding()
        .background(Theme.Colors.appBackground)
}
