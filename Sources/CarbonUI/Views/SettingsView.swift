import SwiftUI
import ServiceManagement
import CarbonEngine

public struct SettingsView: View {
    @Bindable var viewModel: CarbonViewModel
    @State private var searchText = ""
    @State private var showClearConfirmation = false

    public init(viewModel: CarbonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Carbon: Launch at Login toggle failed: \(error)")
                        }
                    }
                ))
            }

            Section("Carbon Region") {
                TextField("Search regions...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Picker("Grid Region", selection: Binding(
                    get: { viewModel.regionCode },
                    set: { viewModel.updateRegion($0) }
                )) {
                    ForEach(filteredRegions, id: \.key) { key, value in
                        Text("\(flag(key)) \(key) \u{2014} \(Int(value)) gCO\u{2082}/kWh")
                            .tag(key)
                    }
                }
                .pickerStyle(.menu)

                Text("Current intensity: \(Int(viewModel.carbonIntensity)) gCO\u{2082}/kWh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("System") {
                LabeledContent("Chip", value: viewModel.chipInfo.displayName)
                LabeledContent("CPU Cores", value: "\(viewModel.chipInfo.cpuCoreCount)")
                LabeledContent("CPU TDP", value: "\(Int(viewModel.chipInfo.tdpWatts)) W")
                LabeledContent("GPU TDP", value: "\(Int(viewModel.chipInfo.gpuBaseTDP)) W")
            }

            Section("Data") {
                if let url = viewModel.databaseURL {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                    }
                }

                Button("Clear All Data", role: .destructive) {
                    showClearConfirmation = true
                }
                .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        Task { await viewModel.clearAllData() }
                    }
                } message: {
                    Text("This will permanently delete all recorded energy samples. This action cannot be undone.")
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Data", value: "~/Library/Application Support/Carbon/")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 420)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var filteredRegions: [(key: String, value: Double)] {
        let all = CarbonIntensityTable.table.sorted { $0.key < $1.key }
        guard !searchText.isEmpty else { return all }
        let query = searchText.lowercased()
        return all.filter { $0.key.lowercased().contains(query) }
    }

    private func flag(_ code: String) -> String {
        let base: UInt32 = 127397
        return code.unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map(String.init).joined()
    }
}
