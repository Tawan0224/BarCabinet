import Foundation
import Observation

@MainActor
@Observable
final class AddIngredientViewModel {
    var all: [String] = []
    var isLoading = false
    var errorMessage: String?
    var searchText: String = ""

    private let api: CocktailAPI

    init(api: CocktailAPI = .shared) {
        self.api = api
    }

    func load() async {
        guard all.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            all = try await api.listIngredients()
        } catch {
            errorMessage = "Couldn't load ingredients."
        }
    }

    func available(excluding cabinet: Set<String>) -> [String] {
        let remaining = all.filter { !cabinet.contains($0.lowercased()) }
        guard !searchText.isEmpty else { return remaining }
        return remaining.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
