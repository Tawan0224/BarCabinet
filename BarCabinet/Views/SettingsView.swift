import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker(selection: $appearanceRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode.rawValue)
                        }
                    } label: {
                        Text("Theme")
                    }
                    .pickerStyle(.inline)
                }

                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Bar Cabinet")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Data")
                        Spacer()
                        Text("TheCocktailDB")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
