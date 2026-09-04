import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    private let resultsColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let popularColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var showingResults: Bool {
        viewModel.hasSearched || viewModel.isSearching || viewModel.errorMessage != nil
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .navigationDestination(for: DrinkSummary.self) { drink in
                    MixGuideView(drinkID: drink.id)
                }
                .toolbar {
                    if showingResults {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                clearAll()
                            }
                        }
                    }
                }
                .searchable(
                    text: $viewModel.nameQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search by drink name"
                )
                .onSubmit(of: .search) {
                    Task { await viewModel.searchByName() }
                }
                .onChange(of: viewModel.nameQuery) { _, newValue in
                    if newValue.isEmpty && viewModel.ingredientQuery.isEmpty {
                        viewModel.reset()
                    }
                }
        }
    }

    private func clearAll() {
        viewModel.nameQuery = ""
        viewModel.ingredientQuery = ""
        viewModel.reset()
    }

    @ViewBuilder
    private var content: some View {
        if showingResults {
            resultsView
        } else {
            idleView
        }
    }

    private var idleView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ingredientSection
                popularSection
                if !viewModel.recent.isEmpty {
                    recentSection
                }
            }
            .padding(.vertical)
        }
    }

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search by ingredient")
                .font(.headline)
                .padding(.horizontal)
            HStack {
                Image(systemName: "leaf")
                    .foregroundStyle(.secondary)
                TextField("e.g. Lemon, Mint, Vodka", text: $viewModel.ingredientQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.searchByIngredient() }
                    }
                if !viewModel.ingredientQuery.isEmpty {
                    Button {
                        viewModel.ingredientQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular ingredients")
                .font(.headline)
                .padding(.horizontal)
            LazyVGrid(columns: popularColumns, spacing: 10) {
                ForEach(viewModel.popularIngredients, id: \.self) { name in
                    Button {
                        Task { await viewModel.searchByIngredient(name) }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: symbol(for: name))
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                                .frame(height: 32)
                            Text(name)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent searches")
                .font(.headline)
                .padding(.horizontal)
            VStack(spacing: 0) {
                ForEach(viewModel.recent, id: \.self) { term in
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Button {
                            viewModel.ingredientQuery = ""
                            viewModel.nameQuery = term
                            Task { await viewModel.searchByName() }
                        } label: {
                            Text(term)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Button {
                            viewModel.removeRecent(term)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    if term != viewModel.recent.last {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var resultsView: some View {
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
                Button("Back") { clearAll() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.results.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No drinks found.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Back") { clearAll() }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: resultsColumns, spacing: 12) {
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
        }
    }

    private func symbol(for ingredient: String) -> String {
        switch ingredient.lowercased() {
        case "lemon", "lime": return "leaf.circle"
        case "mint": return "leaf.fill"
        case "vodka", "rum", "gin", "whisky", "whiskey": return "wineglass"
        default: return "drop"
        }
    }
}

#Preview {
    SearchView()
}
