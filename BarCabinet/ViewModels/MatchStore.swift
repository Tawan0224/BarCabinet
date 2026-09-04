import Foundation
import Observation

@MainActor
@Observable
final class MatchStore {
    var matches: [DrinkSummary] = []
    var isComputing = false

    // Fast strategy: TheCocktailDB's `search.php?f=<letter>` returns full drink details
    // (including ingredients) in one call. Fetching a–z + 0–9 in parallel gets ~426 drinks
    // in ~1s. We also search by each cabinet ingredient name to catch drinks whose names
    // fall past the 25-per-letter cap (e.g. "Banana Strawberry Shake" isn't in the first
    // 25 'B' drinks, but shows up when we search "banana"). Union both, filter to drinks
    // whose ingredients are all in the cabinet.
    private let alphanumerics = Array("abcdefghijklmnopqrstuvwxyz0123456789").map(String.init)

    private let api: CocktailAPI
    private var lastKey: String?

    init(api: CocktailAPI = .shared) {
        self.api = api
    }

    func invalidate() {
        lastKey = nil
    }

    private static func runWithRetry<T>(_ block: () async throws -> [T], attempts: Int = 6) async -> [T] {
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

    func compute(cabinet: [CabinetIngredient]) async {
        let key = cabinet.map { $0.name.lowercased() }.sorted().joined(separator: "|")
        guard key != lastKey else { return }

        guard !cabinet.isEmpty else {
            matches = []
            lastKey = key
            return
        }

        isComputing = true
        defer { isComputing = false }

        let cabinetSet = Set(cabinet.map { $0.name.lowercased() })
        let cabinetNames = cabinet.map(\.name)
        let api = self.api

        // Queue every request; bounded concurrency with retries. The free API throttles
        // bursts hard and starts returning empty responses, so we retry with backoff.
        var queries: [(String, () async throws -> [Drink])] = []
        for letter in alphanumerics {
            queries.append(("f=\(letter)", { try await api.drinks(startingWith: letter) }))
        }
        for name in cabinetNames {
            queries.append(("s=\(name)", { try await api.drinks(named: name) }))
        }

        var pool: [String: Drink] = [:]
        await withTaskGroup(of: [Drink].self) { group in
            var iterator = queries.makeIterator()
            let concurrency = 4
            for _ in 0..<concurrency {
                if let next = iterator.next() {
                    group.addTask { await Self.runWithRetry(next.1) }
                }
            }
            while let list = await group.next() {
                for d in list { pool[d.id] = d }
                if let next = iterator.next() {
                    group.addTask { await Self.runWithRetry(next.1) }
                }
            }
        }

        if Task.isCancelled { return }

        let matched = pool.values.filter { drink in
            drink.ingredients.allSatisfy { cabinetSet.contains($0.name.lowercased()) }
        }

        matches = matched
            .map { DrinkSummary(id: $0.id, name: $0.name, thumbnailURL: $0.thumbnailURL) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        lastKey = key
    }
}
