import SwiftUI

struct AllDrinksView: View {
    let title: String
    let drinks: [DrinkSummary]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if drinks.isEmpty {
                Text("No drinks to show.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(drinks) { drink in
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AllDrinksView(title: "All Cocktails", drinks: [])
    }
}
