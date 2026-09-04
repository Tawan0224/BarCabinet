import Foundation
import Observation

@MainActor
@Observable
final class MixGuideViewModel {
    let drinkID: String
    var drink: Drink?
    var isLoading = false
    var errorMessage: String?

    private let api: CocktailAPI

    init(drinkID: String, api: CocktailAPI = .shared) {
        self.drinkID = drinkID
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if let result = try await api.drink(withID: drinkID) {
                drink = result
            } else {
                errorMessage = "This drink couldn't be found."
            }
        } catch {
            errorMessage = "Couldn't load this drink. Check your connection and try again."
        }
    }

    // TheCocktailDB returns instructions as one paragraph with period-separated sentences.
    var steps: [String] {
        guard let instructions = drink?.instructions else { return [] }
        return instructions
            .components(separatedBy: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
