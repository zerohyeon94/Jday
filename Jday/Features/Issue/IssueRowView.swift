import SwiftUI

/// 이슈 목록 카드 행 (iOS) / 리스트 행 (macOS 공용)
struct IssueRowView: View {
    let issue: Issue
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(issue.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(issue.createdAt.shortMonthDay) 등록")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(isResolved: issue.isResolved)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(issue.title), \(issue.isResolved ? "해결완료" : "미해결"), \(issue.createdAt.shortMonthDay) 등록")
    }
}
