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
                ForEach(apps) { app in
                    AppRowView(app: app)
                    if app.id != apps.last?.id {
                        Divider().padding(.horizontal, 12)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
}
