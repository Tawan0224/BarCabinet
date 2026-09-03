import Foundation

struct Ingredient: Hashable, Codable {
    let name: String
    let measure: String?
}

struct Drink: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let thumbnailURL: URL?
    let category: String?
    let alcoholic: String?
    let glass: String?
    let instructions: String?
    let ingredients: [Ingredient]

    private enum CodingKeys: String, CodingKey {
        case id = "idDrink"
        case name = "strDrink"
        case thumbnailURL = "strDrinkThumb"
        case category = "strCategory"
        case alcoholic = "strAlcoholic"
        case glass = "strGlass"
        case instructions = "strInstructions"
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.thumbnailURL = (try c.decodeIfPresent(String.self, forKey: .thumbnailURL)).flatMap(URL.init(string:))
        self.category = try c.decodeIfPresent(String.self, forKey: .category)
        self.alcoholic = try c.decodeIfPresent(String.self, forKey: .alcoholic)
        self.glass = try c.decodeIfPresent(String.self, forKey: .glass)
        self.instructions = try c.decodeIfPresent(String.self, forKey: .instructions)

        // The API returns 15 flat strIngredientN / strMeasureN pairs, mostly empty.
        // Fold them into one clean array, dropping blanks and trimming whitespace.
        let raw = try decoder.container(keyedBy: DynamicKey.self)
        var folded: [Ingredient] = []
        for i in 1...15 {
            guard
                let nameKey = DynamicKey(stringValue: "strIngredient\(i)"),
                let measureKey = DynamicKey(stringValue: "strMeasure\(i)")
            else { continue }
            let rawName = try raw.decodeIfPresent(String.self, forKey: nameKey)
            let cleanName = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !cleanName.isEmpty else { continue }
            let rawMeasure = try raw.decodeIfPresent(String.self, forKey: measureKey)
            let cleanMeasure = rawMeasure?.trimmingCharacters(in: .whitespacesAndNewlines)
            folded.append(Ingredient(
                name: cleanName,
                measure: (cleanMeasure?.isEmpty == false) ? cleanMeasure : nil
            ))
        }
        self.ingredients = folded
    }
}

struct DrinkSummary: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let thumbnailURL: URL?

    private enum CodingKeys: String, CodingKey {
        case id = "idDrink"
        case name = "strDrink"
        case thumbnailURL = "strDrinkThumb"
    }

    init(id: String, name: String, thumbnailURL: URL?) {
        self.id = id
        self.name = name
        self.thumbnailURL = thumbnailURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.thumbnailURL = (try c.decodeIfPresent(String.self, forKey: .thumbnailURL)).flatMap(URL.init(string:))
    }

    init(_ drink: Drink) {
        self.init(id: drink.id, name: drink.name, thumbnailURL: drink.thumbnailURL)
    }
}
