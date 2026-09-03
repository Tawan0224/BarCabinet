import SwiftUI

struct MyBarView: View {
    @State private var viewModel = MyBarViewModel()

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
                case .cabinet:
                    cabinet
                case .favorites:
                    favorites
                }
            }
            .navigationTitle("My Bar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var cabinet: some View {
        VStack(spacing: 0) {
            madeCountCard

            List {
                Section("My ingredients") {
                    if viewModel.ingredients.isEmpty {
                        Text("No ingredients yet — tap + to add one.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(viewModel.ingredients, id: \.self) { name in
                            Text(name)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var favorites: some View {
        List {
            if viewModel.favorites.isEmpty {
                Text("No saved drinks yet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(viewModel.favorites) { drink in
                    Text(drink.name)
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
                Text("\(viewModel.madeCount) drinks")
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    MyBarView()
}
