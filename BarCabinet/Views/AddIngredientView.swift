import SwiftUI
import SwiftData

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var cabinet: [CabinetIngredient]

    @State private var viewModel = AddIngredientViewModel()

    private var cabinetSet: Set<String> {
        Set(cabinet.map { $0.name.lowercased() })
    }

    private var pendingCustomName: String? {
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !cabinetSet.contains(trimmed.lowercased()) else { return nil }
        let existsInList = viewModel.all.contains {
            $0.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !existsInList else { return nil }
        return trimmed
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add ingredient")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: "Search or type an ingredient")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
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
                Button("Try again") { Task { await viewModel.load() } }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            list
        }
    }

    private var list: some View {
        let available = viewModel.available(excluding: cabinetSet)
        return List {
            if let name = pendingCustomName {
                Section {
                    Button {
                        add(name)
                        viewModel.searchText = ""
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Add \"\(name)\"")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if !available.isEmpty {
                Section {
                    ForEach(available, id: \.self) { name in
                        Button {
                            add(name)
                        } label: {
                            HStack {
                                Text(name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    if pendingCustomName != nil {
                        Text("Suggestions")
                    }
                }
            } else if pendingCustomName == nil {
                Text(viewModel.searchText.isEmpty
                     ? "You've added every suggested ingredient."
                     : "No matches.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !cabinetSet.contains(trimmed.lowercased()) else { return }
        modelContext.insert(CabinetIngredient(name: trimmed))
    }
}

#Preview {
    AddIngredientView()
        .modelContainer(for: [CabinetIngredient.self, FavoriteDrink.self], inMemory: true)
}
