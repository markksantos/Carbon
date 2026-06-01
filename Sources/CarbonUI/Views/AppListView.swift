import SwiftUI
import CarbonEngine

public struct AppListView: View {
    let apps: [AppEnergySnapshot]

    public init(apps: [AppEnergySnapshot]) {
        self.apps = apps
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Column headers
                HStack(spacing: 8) {
                    Text("App")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("CPU")
                        .frame(width: 40, alignment: .trailing)
                    Text("Watts")
                        .frame(width: 50, alignment: .trailing)
                    Text("Impact")
                        .frame(width: 52, alignment: .trailing)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

                Divider().padding(.horizontal, 12)

                ForEach(apps) { app in
                    AppRowView(app: app)
                    if app.id != apps.last?.id {
                        Divider().padding(.horizontal, 12)
                    }
                }
                .animation(.default, value: apps.map(\.id))
            }
        }
        .frame(maxHeight: 300)
    }
}
