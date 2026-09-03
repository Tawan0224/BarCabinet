import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

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

                List {
                    Section("Recent searches") {
                        ForEach(viewModel.recent, id: \.self) { term in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                Text(term)
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
                .listStyle(.plain)
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: viewModel.mode == .name ? "Search cocktails" : "Enter an ingredient"
            )
        }
    }
}

#Preview {
    SearchView()
}
