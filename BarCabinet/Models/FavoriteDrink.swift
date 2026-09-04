import Foundation
import SwiftData

@Model
final class FavoriteDrink {
    @Attribute(.unique) var id: String
    var name: String
    var thumbnailURLString: String?
    var ingredientNames: [String] = []
    var savedAt: Date

    init(
        id: String,
        name: String,
        thumbnailURLString: String?,
        ingredientNames: [String] = [],
        savedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.thumbnailURLString = thumbnailURLString
        self.ingredientNames = ingredientNames
        self.savedAt = savedAt
    }
}

extension FavoriteDrink {
    var thumbnailURL: URL? {
        thumbnailURLString.flatMap(URL.init(string:))
    }

    var asSummary: DrinkSummary {
        DrinkSummary(id: id, name: name, thumbnailURL: thumbnailURL)
    }
}
