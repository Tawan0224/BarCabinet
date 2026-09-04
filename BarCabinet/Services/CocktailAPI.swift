import Foundation

enum CocktailAPIError: Error {
    case badResponse(Int)
    case decoding(Error)
    case transport(Error)
}

struct CocktailAPI: Sendable {
    static let shared = CocktailAPI()

    private let base = URL(string: "https://www.thecocktaildb.com/api/json/v1/1/")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // The API wraps every response in `{ "drinks": [...] }` and returns `null` for no results.
    private struct Envelope<T: Decodable>: Decodable {
        let drinks: [T]?
    }

    func drink(withID id: String) async throws -> Drink? {
        let env: Envelope<Drink> = try await get("lookup.php", query: [.init(name: "i", value: id)])
        return env.drinks?.first
    }

    func drinks(withIngredient ingredient: String) async throws -> [DrinkSummary] {
        let env: Envelope<DrinkSummary> = try await get("filter.php", query: [.init(name: "i", value: ingredient)])
        return env.drinks ?? []
    }

    func drinks(inCategory category: String) async throws -> [DrinkSummary] {
        let env: Envelope<DrinkSummary> = try await get("filter.php", query: [.init(name: "c", value: category)])
        return env.drinks ?? []
    }

    func drinks(alcoholic value: String) async throws -> [DrinkSummary] {
        let env: Envelope<DrinkSummary> = try await get("filter.php", query: [.init(name: "a", value: value)])
        return env.drinks ?? []
    }

    func drinks(named name: String) async throws -> [Drink] {
        let env: Envelope<Drink> = try await get("search.php", query: [.init(name: "s", value: name)])
        return env.drinks ?? []
    }

    func randomDrink() async throws -> Drink? {
        let env: Envelope<Drink> = try await get("random.php", query: [])
        return env.drinks?.first
    }

    /// Full drinks whose names start with a letter/digit. Returns full ingredients.
    func drinks(startingWith letter: String) async throws -> [Drink] {
        let env: Envelope<Drink> = try await get("search.php", query: [.init(name: "f", value: letter)])
        return env.drinks ?? []
    }

    func listIngredients() async throws -> [String] {
        struct Row: Decodable { let strIngredient1: String }
        let env: Envelope<Row> = try await get("list.php", query: [.init(name: "i", value: "list")])
        return (env.drinks ?? [])
            .map(\.strIngredient1)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        let url = base.appendingPathComponent(path).appending(queryItems: query)
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw CocktailAPIError.transport(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw CocktailAPIError.badResponse(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CocktailAPIError.decoding(error)
        }
    }
}
