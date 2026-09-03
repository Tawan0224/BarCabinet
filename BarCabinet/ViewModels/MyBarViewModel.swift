import Foundation
import Observation

enum MyBarSection: String, CaseIterable, Identifiable {
    case cabinet = "My Bar"
    case favorites = "Favorites"
    var id: String { rawValue }
}

@MainActor
@Observable
final class MyBarViewModel {
    var section: MyBarSection = .cabinet
    var ingredients: [String] = []
    var favorites: [DrinkSummary] = []

    var madeCount: Int { 0 }
}
