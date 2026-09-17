import Foundation

enum EventCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case music = "Music"
    case food = "Food"
    case arts = "Arts"
    case sports = "Sports"
    case nightlife = "Nightlife"
    case outdoors = "Outdoors"
    case community = "Community"
    case comedy = "Comedy"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .music: return "music.note"
        case .food: return "fork.knife"
        case .arts: return "paintpalette"
        case .sports: return "sportscourt"
        case .nightlife: return "moon.stars"
        case .outdoors: return "leaf"
        case .community: return "person.3"
        case .comedy: return "face.smiling"
        }
    }
}
