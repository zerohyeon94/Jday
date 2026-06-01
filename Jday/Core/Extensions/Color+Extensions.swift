import SwiftUI

extension Color {
    static var priorityLow: Color { .blue }
    static var priorityMedium: Color { .orange }
    static var priorityHigh: Color { .red }

    static func priority(_ p: Priority) -> Color {
        switch p {
        case .low: .priorityLow
        case .medium: .priorityMedium
        case .high: .priorityHigh
        }
    }
}
