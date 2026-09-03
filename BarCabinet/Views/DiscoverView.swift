import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    filterChips

                    HStack {
                        Text("Popular")
                            .font(.title2.bold())
                        Spacer()
                    }
                    .padding(.horizontal)

                    content
                }
                .padding(.vertical)
            }
            .navigationTitle("Cocktail Craft")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "shuffle")
                    }
                }
            }
            .task(id: viewModel.filter) {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.drinks.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await viewModel.load() } }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.drinks.isEmpty {
            Text("No drinks found.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.drinks) { drink in
                    DrinkCard(drink: drink)
                }
            }
            .padding(.horizontal)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Good evening")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("What will you mix today?")
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DrinkTypeFilter.allCases) { option in
                    Button {
                        viewModel.filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(viewModel.filter == option ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                Capsule().stroke(viewModel.filter == option ? Color.accentColor : .clear, lineWidth: 1)
                            )
                            .foregroundStyle(viewModel.filter == option ? Color.accentColor : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct DrinkCard: View {
    let drink: DrinkSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: drink.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "wineglass")
                        .font(.largeTitle)
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
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(drink.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
    }
}

#Preview {
    DiscoverView()
}
