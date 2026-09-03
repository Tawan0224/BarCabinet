import Foundation
import Observation

enum SearchMode: String, CaseIterable, Identifiable {
    case name = "By name"
    case ingredient = "By ingredient"
    var id: String { rawValue }
}

@MainActor
@Observable
final class SearchViewModel {
    var query: String = ""
    var mode: SearchMode = .name
    var recent: [String] = ["Mojito", "Whiskey sour", "Lime"]

    func removeRecent(_ term: String) {
        recent.removeAll { $0 == term }
    }
}
