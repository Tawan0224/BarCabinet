import SwiftUI

struct MixGuideView: View {
    @State private var viewModel: MixGuideViewModel

    init(drinkID: String) {
        _viewModel = State(initialValue: MixGuideViewModel(drinkID: drinkID))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.drink == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let drink = viewModel.drink {
                content(for: drink)
            } else if let errorMessage = viewModel.errorMessage {
                errorState(errorMessage)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite ? .red : Color.primary)
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
                    HStack(spacing: 12) {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
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
            viewModel.toggleFavorite()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isFavorite ? "bookmark.fill" : "bookmark")
                Text(viewModel.isFavorite ? "Saved to My Bar" : "Add to My Bar")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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
}

#Preview {
    NavigationStack {
        MixGuideView(drinkID: "11007")
    }
}
