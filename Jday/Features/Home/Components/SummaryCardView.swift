import SwiftUI

struct SummaryCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, color: Color = .accentColor) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    HStack {
        SummaryCardView(title: "남은 할 일", value: "3", color: .blue)
        SummaryCardView(title: "오늘 일정", value: "2", color: .green)
        SummaryCardView(title: "진행률", value: "60%", color: .orange)
    }
    .padding()
}
