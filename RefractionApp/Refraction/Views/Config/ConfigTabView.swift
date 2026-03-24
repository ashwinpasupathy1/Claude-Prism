// ConfigTabView.swift — Tab bar wrapping the four configuration panels:
// Data, Axes, Style, and Stats.

import SwiftUI

struct ConfigTabView: View {

    @Environment(AppState.self) private var appState

    enum Tab: String, CaseIterable, Identifiable {
        case data = "Data"
        case axes = "Axes"
        case style = "Style"
        case stats = "Stats"

        var id: String { rawValue }

        var sfSymbol: String {
            switch self {
            case .data:  return "doc.fill"
            case .axes:  return "ruler"
            case .style: return "paintbrush.fill"
            case .stats: return "function"
            }
        }
    }

    @State private var selectedTab: Tab = .data

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.sfSymbol)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedTab == tab
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.bar)

            Divider()

            // Tab content
            switch selectedTab {
            case .data:
                DataTabView()
            case .axes:
                AxesTabView()
            case .style:
                StyleTabView()
            case .stats:
                if appState.selectedChartType.hasStats {
                    StatsTabView()
                } else {
                    ContentUnavailableView(
                        "No Statistics",
                        systemImage: "function",
                        description: Text("This chart type does not support statistical tests.")
                    )
                }
            }
        }
    }
}
