import SwiftUI

/// Application preferences and information.
struct SettingsView: View {
    @AppStorage(SettingsKey.animationsEnabled)
    private var animationsEnabled = true

    @AppStorage(SettingsKey.animationSpeed)
    private var animationSpeed = 1.0

    @AppStorage(SettingsKey.showPlacementHints)
    private var showPlacementHints = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Animate scenes", isOn: $animationsEnabled)
                    Picker("Speed", selection: $animationSpeed) {
                        Text("Slow").tag(0.5)
                        Text("Normal").tag(1.0)
                        Text("Fast").tag(1.5)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!animationsEnabled)
                } header: {
                    Text("Animation")
                } footer: {
                    Text("Controls orbital motion, planet rotation and mission animations.")
                }

                Section {
                    Toggle("Show placement hints", isOn: $showPlacementHints)
                } header: {
                    Text("Augmented Reality")
                } footer: {
                    Text("Camera access is requested the first time an AR experience is launched.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                    LabeledContent("Target device", value: "iPad Air (M1)")
                    Text("SolarScope places the Solar System, Mars exploration missions and the International Space Station into your space using markerless augmented reality.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

#Preview {
    SettingsView()
}
