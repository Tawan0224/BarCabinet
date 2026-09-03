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

    init(api: CocktailAPI = .shared) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            drinks = try await fetch()
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
