import SwiftUI
import SwiftData

struct MixGuideView: View {
    @State private var viewModel: MixGuideViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteDrink]
    @Query private var cabinet: [CabinetIngredient]

    init(drinkID: String) {
        _viewModel = State(initialValue: MixGuideViewModel(drinkID: drinkID))
    }

    private var isFavorite: Bool {
        favorites.contains { $0.id == viewModel.drinkID }
    }

    private var cabinetSet: Set<String> {
        Set(cabinet.map { $0.name.lowercased() })
    }

    var body: some View {
        Group {
            if let drink = viewModel.drink {
                content(for: drink)
            } else if let errorMessage = viewModel.errorMessage {
                errorState(errorMessage)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : Color.primary)
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func content(for drink: Drink) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photo(drink)

                VStack(alignment: .leading, spacing: 4) {
                    Text(drink.name)
                        .font(.largeTitle.bold())
                    if let glass = drink.glass {
                        Text(glass)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                ingredientsSection(drink)

                if !viewModel.steps.isEmpty {
                    instructionsSection
                }

                addButton
                    .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }

    private func photo(_ drink: Drink) -> some View {
        AsyncImage(url: drink.thumbnailURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "wineglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.tertiary)
            case .empty:
                ProgressView()
            @unknown default:
                Color.clear
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.secondarySystemBackground))
        .clipped()
    }

    private func ingredientsSection(_ drink: Drink) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2.bold())

            VStack(spacing: 10) {
                ForEach(drink.ingredients, id: \.self) { ingredient in
                    let owned = cabinetSet.contains(ingredient.name.lowercased())
                    HStack(spacing: 12) {
                        Image(systemName: owned ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(owned ? Color.accentColor : .secondary)
                        Text(ingredient.name)
                        Spacer()
                        if let measure = ingredient.measure {
                            Text(measure)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.body.bold())
                            .foregroundStyle(Color.accentColor)
                        Text(step)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var addButton: some View {
        Button {
            toggleFavorite()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                Text(isFavorite ? "Saved to Favorites" : "Save to Favorites")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try again") { Task { await viewModel.load() } }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.id == viewModel.drinkID }) {
            modelContext.delete(existing)
            return
        }
        guard let drink = viewModel.drink else { return }
        modelContext.insert(FavoriteDrink(
            id: drink.id,
            name: drink.name,
            thumbnailURLString: drink.thumbnailURL?.absoluteString,
            ingredientNames: drink.ingredients.map(\.name)
        ))
    }
}

#Preview {
    NavigationStack {
        MixGuideView(drinkID: "11007")
    }
    .modelContainer(for: [FavoriteDrink.self, CabinetIngredient.self], inMemory: true)
}
