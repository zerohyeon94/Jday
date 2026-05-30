import Foundation

enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var label: String {
        switch self {
        case .low: String(localized: "낮음")
        case .medium: String(localized: "중간")
        case .high: String(localized: "높음")
        }
    }
}
