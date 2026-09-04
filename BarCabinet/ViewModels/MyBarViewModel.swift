import Foundation
import Observation

enum MyBarSection: String, CaseIterable, Identifiable {
    case ingredients = "Ingredients"
    case favorites = "Favorites"
    var id: String { rawValue }
}

@MainActor
@Observable
final class MyBarViewModel {
    var section: MyBarSection = .ingredients
}
