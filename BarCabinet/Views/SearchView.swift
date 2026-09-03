import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(SearchMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                content
            }
            .navigationTitle("Search")
            .navigationDestination(for: DrinkSummary.self) { drink in
                MixGuideView(drinkID: drink.id)
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: viewModel.mode == .name ? "Search cocktails" : "Enter an ingredient"
            )
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .onChange(of: viewModel.query) { _, newValue in
                if newValue.isEmpty { viewModel.reset() }
            }
            .onChange(of: viewModel.mode) { _, _ in
                viewModel.reset()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await viewModel.search() } }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.hasSearched && viewModel.results.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No drinks found for \"\(viewModel.query)\".")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.results.isEmpty {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.results) { drink in
                        NavigationLink(value: drink) {
                            DrinkCard(drink: drink)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        } else {
            recentSearches
        }
    }

    private var recentSearches: some View {
        List {
            if viewModel.recent.isEmpty {
                Text(viewModel.mode == .name
                     ? "Search for a cocktail by name."
                     : "Enter an ingredient to find drinks that use it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Section("Recent searches") {
                    ForEach(viewModel.recent, id: \.self) { term in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Button {
                                Task { await viewModel.selectRecent(term) }
                            } label: {
                                Text(term)
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button {
                                viewModel.removeRecent(term)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    SearchView()
}
