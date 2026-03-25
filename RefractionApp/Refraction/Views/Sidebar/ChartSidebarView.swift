// ChartSidebarView.swift — Deprecated: chart type selection is now handled
// by NavigatorView. This stub remains for any residual references.

import SwiftUI

struct ChartSidebarView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        // Chart type selection has moved to NavigatorView / Sheet.kind.
        // This view is kept as a minimal stub for compilation.
        ContentUnavailableView(
            "Use Navigator",
            systemImage: "sidebar.left",
            description: Text("Chart type selection has moved to the navigator sidebar.")
        )
    }
}
