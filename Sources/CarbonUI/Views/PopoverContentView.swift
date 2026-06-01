import SwiftUI
import CarbonEngine

public struct PopoverContentView: View {
    @Bindable var viewModel: CarbonViewModel

    public init(viewModel: CarbonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if viewModel.gpuUtilization > 0 {
                GPUInfoView(
                    utilization: viewModel.gpuUtilization,
                    watts: viewModel.systemSnapshot?.gpuWatts ?? 0
                )
            }
            Divider()
            tabPicker
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 340)
        .background(.clear)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Energy Monitor")
                    .font(.headline)
                Text(viewModel.chipInfo.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f W", viewModel.totalWatts))
                    .font(.title2.monospacedDigit())
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.totalWatts)
                if viewModel.gpuUtilization > 0 {
                    Text(String(format: "GPU %.0f%%", viewModel.gpuUtilization))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabPicker: some View {
        Picker("", selection: Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.selectTab($0) }
        )) {
            ForEach(CarbonViewModel.Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .live:
            if let snapshot = viewModel.systemSnapshot, !snapshot.appSnapshots.isEmpty {
                AppListView(apps: snapshot.appSnapshots)
            } else {
                measuringPlaceholder
            }
        case .today:
            if viewModel.dailySummaries.isEmpty {
                placeholder("No data yet today")
            } else {
                DailySummaryView(summaries: viewModel.dailySummaries)
            }
        case .week:
            if viewModel.weeklySummaries.isEmpty {
                placeholder("No weekly data yet")
            } else {
                WeeklySummaryView(
                    dailyTotals: viewModel.weeklySummaries,
                    carbonIntensity: viewModel.carbonIntensity,
                    viewModel: viewModel
                )
            }
        }

        // Phase 3: Suggestions
        if !viewModel.suggestions.isEmpty && viewModel.selectedTab == .live {
            Divider()
            SuggestionsView(suggestions: viewModel.suggestions)
        }
    }

    private var footer: some View {
        HStack {
            if let snapshot = viewModel.systemSnapshot {
                Text("Display: \(String(format: "%.1f W", snapshot.displayWatts))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let lastUpdated = viewModel.lastUpdated {
                Text(lastUpdated, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(viewModel.regionCode)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var measuringPlaceholder: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Measuring...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}
