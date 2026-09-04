import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var nameQuery: String = ""
    var ingredientQuery: String = ""
    var results: [DrinkSummary] = []
    var recent: [String] = []
    var isSearching = false
    var errorMessage: String?
    var hasSearched = false

    let popularIngredients = ["Vodka", "Rum", "Gin", "Whisky", "Lemon", "Mint"]

    private let api: CocktailAPI
    private let recentLimit = 10

    init(api: CocktailAPI = .shared) {
        self.api = api
    }

    func searchByName() async {
        let term = nameQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            reset()
            return
        }
        await run(term: term) {
            let drinks = try await api.drinks(named: term)
            return drinks.map(DrinkSummary.init)
        }
    }

    func searchByIngredient(_ override: String? = nil) async {
        let raw = override ?? ingredientQuery
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            reset()
            return
        }
        ingredientQuery = term
        await run(term: term) {
            // The free API's `filter.php?i=` returns only 1 drink. To actually find
            // every drink that uses the ingredient, scan the full drink catalogue via
            // `search.php?f=<letter>` (bulk, with ingredients) and filter locally.
            let pool = try await fetchDrinkPool(extraName: term)
            return pool.values
                .filter { drink in
                    drink.ingredients.contains { $0.name.localizedCaseInsensitiveContains(term) }
                }
                .map(DrinkSummary.init)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private func fetchDrinkPool(extraName: String?) async throws -> [String: Drink] {
        let letters = Array("abcdefghijklmnopqrstuvwxyz0123456789").map(String.init)
        let api = self.api
        var queries: [() async throws -> [Drink]] = []
        for l in letters {
            queries.append { try await api.drinks(startingWith: l) }
        }
        if let extraName {
            queries.append { try await api.drinks(named: extraName) }
        }

        var pool: [String: Drink] = [:]
        await withTaskGroup(of: [Drink].self) { group in
            var iterator = queries.makeIterator()
            let concurrency = 4
            for _ in 0..<concurrency {
                if let next = iterator.next() {
                    group.addTask { await Self.runWithRetry(next) }
                }
            }
            while let list = await group.next() {
                for d in list { pool[d.id] = d }
                if let next = iterator.next() {
                    group.addTask { await Self.runWithRetry(next) }
                }
            }
        }
        return pool
    }

    private static func runWithRetry(_ block: () async throws -> [Drink], attempts: Int = 6) async -> [Drink] {
        var delay: UInt64 = 300_000_000
        for attempt in 0..<attempts {
            do {
                return try await block()
            } catch {
                if attempt == attempts - 1 { return [] }
                try? await Task.sleep(nanoseconds: delay)
                delay *= 2
            }
        }
        return []
    }

    func reset() {
        results = []
        hasSearched = false
        errorMessage = nil
    }

    func removeRecent(_ term: String) {
        recent.removeAll { $0 == term }
    }

    private func run(term: String, _ fetch: () async throws -> [DrinkSummary]) async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            results = try await fetch()
            hasSearched = true
            addRecent(term)
        } catch {
            results = []
            hasSearched = true
            errorMessage = "Search failed. Check your connection and try again."
        }
    }

    private func addRecent(_ term: String) {
        recent.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        recent.insert(term, at: 0)
        if recent.count > recentLimit {
            recent = Array(recent.prefix(recentLimit))
        }
    }
}
