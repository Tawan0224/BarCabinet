import SwiftUI
import SwiftData

@main
struct BarCabinetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FavoriteDrink.self, CabinetIngredient.self])
    }
}
