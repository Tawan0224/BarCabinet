import Foundation
import SwiftData

@Model
final class CabinetIngredient {
    @Attribute(.unique) var name: String
    var addedAt: Date

    init(name: String, addedAt: Date = .now) {
        self.name = name
        self.addedAt = addedAt
    }
}
