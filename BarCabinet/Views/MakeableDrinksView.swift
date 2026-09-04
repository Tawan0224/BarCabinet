import SwiftUI
import SwiftData

struct MakeableDrinksView: View {
    let matchStore: MatchStore
    @Query(sort: \CabinetIngredient.name) private var cabinet: [CabinetIngredient]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if matchStore.isComputing && matchStore.matches.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Finding drinks you can make…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if matchStore.matches.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(matchStore.matches) { drink in
                            NavigationLink {
                                MixGuideView(drinkID: drink.id)
                            } label: {
                                DrinkCard(drink: drink)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
        }
        .navigationTitle("You can make")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            matchStore.invalidate()
            await matchStore.compute(cabinet: cabinet)
        }
        .task {
            await matchStore.compute(cabinet: cabinet)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wineglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No drinks match your cabinet yet.")
                .font(.headline)
            Text("Add more ingredients or pull down to refresh.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task {
                    matchStore.invalidate()
                    await matchStore.compute(cabinet: cabinet)
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        MakeableDrinksView(matchStore: MatchStore())
    }
    .modelContainer(for: [CabinetIngredient.self, FavoriteDrink.self], inMemory: true)
}
