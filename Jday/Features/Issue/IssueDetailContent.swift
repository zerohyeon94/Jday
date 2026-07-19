import SwiftUI

/// 이슈 상세 본문 — iOS 시트 / macOS 우측 패널 공용
struct IssueDetailContent: View {
    let issue: Issue
    var onEdit: (() -> Void)?
    let onResolve: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            header

            if let detail = issue.detail, !detail.isEmpty {
                detailCard(detail)
            }

            if issue.drawingData != nil {
                drawingCard
            }

            metaCard

            Spacer(minLength: 0)

            if !issue.isResolved {
                Button(action: onResolve) {
                    Text("해결완료로 표시")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                if let onEdit {
                    Button(action: onEdit) {
                        Label("수정", systemImage: "pencil")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.Colors.brand)
                    .accessibilityHint("이슈 제목, 상세 내용, 알림 시간을 수정합니다")
                }
                Spacer()
                StatusBadge(isResolved: issue.isResolved)
            }
            Text(issue.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailCard(_ detail: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("상세 내용")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var drawingCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("필기 메모")
                .font(.caption)
                .foregroundStyle(.secondary)
            DrawingPreview(data: issue.drawingData)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var metaCard: some View {
        VStack(spacing: 0) {
            metaRow(label: "등록일", value: issue.createdAt.fullTimestamp)
            DashedDivider().padding(.vertical, Theme.Spacing.sm)
            metaRow(
                label: "알림 시간",
                value: issue.notifyAt.map { $0.fullTimestamp } ?? "없음"
            )
            DashedDivider().padding(.vertical, Theme.Spacing.sm)
            metaRow(
                label: "상태",
                value: issue.isResolved ? "해결완료" : "미해결"
            )
        }
        .cardStyle()
    }

    private func metaRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
