import Foundation
import Observation

enum DrinkTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case cocktail = "Cocktail"
    case mocktail = "Mocktail"
    case shake = "Shake"
    var id: String { rawValue }
}

@MainActor
@Observable
final class DiscoverViewModel {
    var filter: DrinkTypeFilter = .all
    var drinks: [DrinkSummary] = []
    var isLoading = false
    var errorMessage: String?

    private let api: CocktailAPI
    private let now: () -> Date
    private let popularCount = 6

    init(api: CocktailAPI = .shared, now: @escaping () -> Date = Date.init) {
        self.api = api
        self.now = now
    }

    var greeting: String {
        switch Calendar.current.component(.hour, from: now()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let all = try await fetch()
            drinks = Array(all.shuffled().prefix(popularCount))
        } catch {
            drinks = []
            errorMessage = "Couldn't load drinks. Check your connection and try again."
        }
    }

    private func fetch() async throws -> [DrinkSummary] {
        switch filter {
        case .all, .cocktail:
            return try await api.drinks(inCategory: "Cocktail")
        case .mocktail:
            return try await api.drinks(alcoholic: "Non_Alcoholic")
        case .shake:
            return try await api.drinks(inCategory: "Shake")
        }
    }
}
