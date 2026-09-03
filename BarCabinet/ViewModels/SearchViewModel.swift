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
    var results: [DrinkSummary] = []
    var recent: [String] = []
    var isSearching = false
    var errorMessage: String?
    var hasSearched = false

    private let api: CocktailAPI
    private let recentLimit = 10

    init(api: CocktailAPI = .shared) {
        self.api = api
    }

    func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            reset()
            return
        }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            switch mode {
            case .name:
                let drinks = try await api.drinks(named: term)
                results = drinks.map(DrinkSummary.init)
            case .ingredient:
                results = try await api.drinks(withIngredient: term)
            }
            hasSearched = true
            addRecent(term)
        } catch {
            results = []
            hasSearched = true
            errorMessage = "Search failed. Check your connection and try again."
        }
    }

    func selectRecent(_ term: String) async {
        query = term
        await search()
    }

    func removeRecent(_ term: String) {
        recent.removeAll { $0 == term }
    }

    func reset() {
        results = []
        hasSearched = false
        errorMessage = nil
    }

    private func addRecent(_ term: String) {
        recent.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        recent.insert(term, at: 0)
        if recent.count > recentLimit {
            recent = Array(recent.prefix(recentLimit))
        }
    }
}
