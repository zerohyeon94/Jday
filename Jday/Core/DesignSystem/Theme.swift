import SwiftUI

/// DayFlow 디자인 시스템 — 색상, 간격, 라운드 값 토큰
enum Theme {
    // MARK: - Colors
    enum Colors {
        static let brand = Color("BrandBlue")
        static let appBackground = Color("AppBackground")
        static let card = Color("CardBackground")
        static let cardStroke = Color("CardStroke")

        static let unresolvedBadgeBackground = brand.opacity(0.12)
        static let resolvedBadgeBackground = Color.gray.opacity(0.18)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: - Radius
    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 12
        static let pill: CGFloat = 999
    }

    // MARK: - Platform metrics
    static var screenPadding: CGFloat {
        #if os(macOS)
        24
        #else
        16
        #endif
    }
}

// MARK: - Card container modifier

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.Colors.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    /// DayFlow 카드 스타일(흰 배경 + 라운드 + 얇은 테두리)
    func cardStyle(padding: CGFloat = Theme.Spacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

/// 점선 구분선 컴포넌트
struct DashedDivider: View {
    var body: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .foregroundStyle(Theme.Colors.cardStroke)
            .frame(height: 1)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}
