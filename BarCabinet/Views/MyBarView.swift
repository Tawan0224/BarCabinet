import SwiftUI
import SwiftData

struct MyBarView: View {
    @State private var viewModel = MyBarViewModel()
    @State private var matchStore = MatchStore()
    @State private var showAddIngredient = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteDrink.savedAt, order: .reverse) private var favorites: [FavoriteDrink]
    @Query(sort: \CabinetIngredient.name) private var cabinet: [CabinetIngredient]

    private var cabinetKey: String {
        cabinet.map { $0.name.lowercased() }.sorted().joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Section", selection: $viewModel.section) {
                    ForEach(MyBarSection.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch viewModel.section {
                case .ingredients:
                    ingredientsList
                case .favorites:
                    favoritesList
                }
            }
            .navigationTitle("My Bar")
            .navigationDestination(for: DrinkSummary.self) { drink in
                MixGuideView(drinkID: drink.id)
            }
            .toolbar {
                if viewModel.section == .ingredients {
                    ToolbarItem(placement: .topBarLeading) {
                        if !cabinet.isEmpty {
                            EditButton()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddIngredient = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddIngredient) {
                AddIngredientView()
            }
            .task(id: cabinetKey) {
                await matchStore.compute(cabinet: cabinet)
            }
        }
    }

    private var ingredientsList: some View {
        VStack(spacing: 0) {
            NavigationLink {
                MakeableDrinksView(matchStore: matchStore)
            } label: {
                madeCountCard
            }
            .buttonStyle(.plain)

            List {
                Section("My ingredients") {
                    if cabinet.isEmpty {
                        Text("No ingredients yet. Tap + to add one.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(cabinet) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Button {
                                    modelContext.delete(item)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                        .imageScale(.large)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove \(item.name)")
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                modelContext.delete(cabinet[i])
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var favoritesList: some View {
        List {
            if favorites.isEmpty {
                Text("No saved drinks yet — tap the heart or \"Save to Favorites\" on a drink.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(favorites) { fav in
                    NavigationLink(value: fav.asSummary) {
                        FavoriteRow(favorite: fav)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(favorites[index])
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var madeCountCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "wineglass")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("You can make")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if matchStore.isComputing {
                    HStack(spacing: 6) {
                        ProgressView()
                        Text("Finding drinks…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    let count = matchStore.matches.count
                    Text("\(count) \(count == 1 ? "drink" : "drinks")")
                        .font(.headline)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

private struct FavoriteRow: View {
    let favorite: FavoriteDrink

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: favorite.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: "wineglass")
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 48, height: 48)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(favorite.name)
                .font(.subheadline.weight(.medium))
        }
    }
}

#Preview {
    MyBarView()
        .modelContainer(for: [FavoriteDrink.self, CabinetIngredient.self], inMemory: true)
}
