import Foundation

enum CocktailAPIError: Error {
    case badResponse(Int)
    case decoding(Error)
    case transport(Error)
}

actor CocktailAPI {
    static let shared = CocktailAPI()

    private let base = URL(string: "https://www.thecocktaildb.com/api/json/v1/1/")!
    private let session: URLSession
    private let decoder = JSONDecoder()

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

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        let url = base.appendingPathComponent(path).appending(queryItems: query)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw CocktailAPIError.transport(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw CocktailAPIError.badResponse(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CocktailAPIError.decoding(error)
        }
    }
}
