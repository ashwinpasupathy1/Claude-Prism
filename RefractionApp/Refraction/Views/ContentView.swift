// ContentView.swift — Root view with permanent sidebar + toolbar banner.
// Uses GeometryReader + HStack for stable layout (no HSplitView).

import SwiftUI

struct ContentView: View {

    @Environment(AppState.self) private var appState
    @Environment(PythonServer.self) private var server

    @State private var sidebarWidth: CGFloat = 240

    var body: some View {
        VStack(spacing: 0) {
            // Prism-style toolbar banner
            ToolbarBanner()

            // Main content: fixed sidebar + detail
            HStack(spacing: 0) {
                // Left: permanent navigator sidebar
                NavigatorView()
                    .frame(width: sidebarWidth)
                    .background(Color(nsColor: .controlBackgroundColor))

                // Draggable divider
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = sidebarWidth + value.translation.width
                                sidebarWidth = min(max(newWidth, 180), 400)
                            }
                    )

                // Right: active sheet content
                contentArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: appState.projectDisplayName) { _, newTitle in
            NSApplication.shared.mainWindow?.title = newTitle
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApplication.shared.mainWindow?.title = appState.projectDisplayName
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    appState.developerMode.toggle()
                } label: {
                    Image(systemName: appState.developerMode ? "curlybraces.square.fill" : "curlybraces.square")
                }
                .help("Toggle Developer Mode (raw JSON)")

                serverStatusIndicator
            }
        }
    }

    // MARK: - Content area: dispatch by sheet kind

    @ViewBuilder
    private var contentArea: some View {
        if let error = appState.error {
            ErrorView(
                errorMessage: error,
                onRetry: {
                    Task { await appState.retryLastAction() }
                },
                onDismiss: {
                    appState.dismissError()
                }
            )
        } else if let sheet = appState.activeSheet {
            switch sheet.kind {
            case .dataTable:
                DataTableView()
            case .graph:
                GraphSheetView(sheet: sheet)
            case .results:
                ResultsSheetView(sheet: sheet)
            case .info:
                InfoSheetView(sheet: sheet)
            }
        } else if !appState.hasDataTables {
            WelcomeView()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 48))
                    .foregroundStyle(.quaternary)
                Text("Select a sheet from the navigator")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Server status

    @ViewBuilder
    private var serverStatusIndicator: some View {
        switch server.state {
        case .idle:
            Label("Server idle", systemImage: "circle")
                .foregroundStyle(.secondary)
                .labelStyle(.iconOnly)
        case .starting:
            ProgressView()
                .controlSize(.small)
                .help("Starting Python server...")
        case .running:
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
                .help("Python server running on port \(PythonServer.port)")
        case .failed(let msg):
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
                .help("Server failed: \(msg)")
        }
    }
}
