// ToolbarBanner.swift — Prism-style toolbar ribbon at the top of the window.
// Placeholder buttons organized by category. Not functional yet.

import SwiftUI

struct ToolbarBanner: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            toolbarGroup("File", items: [
                ("doc.badge.plus", "New"),
                ("folder", "Open"),
                ("square.and.arrow.down", "Save"),
                ("printer", "Print"),
            ])

            divider

            toolbarGroup("Sheet", items: [
                ("tablecells.badge.ellipsis", "New Table"),
                ("trash", "Delete"),
                ("plus", "Add"),
                ("chart.bar.fill", "Graph"),
            ])

            divider

            toolbarGroup("Undo", items: [
                ("arrow.uturn.backward", "Undo"),
                ("arrow.uturn.forward", "Redo"),
            ])

            divider

            toolbarGroup("Clipboard", items: [
                ("scissors", "Cut"),
                ("doc.on.doc", "Copy"),
                ("doc.on.clipboard", "Paste"),
            ])

            divider

            toolbarGroup("Analysis", items: [
                ("function", "Analyze"),
            ])

            divider

            toolbarGroup("Change", items: [
                ("arrow.triangle.2.circlepath", "Swap"),
                ("slider.horizontal.3", "Transform"),
            ])

            divider

            toolbarGroup("Arrange", items: [
                ("rectangle.grid.2x2", "Align"),
                ("arrow.up.and.down.and.arrow.left.and.right", "Distribute"),
            ])

            divider

            toolbarGroup("Draw", items: [
                ("pencil", "Draw"),
                ("line.diagonal", "Line"),
                ("rectangle", "Rectangle"),
            ])

            divider

            toolbarGroup("Write", items: [
                ("textformat", "Text"),
                ("bold", "Bold"),
                ("italic", "Italic"),
            ])

            Spacer()

            toolbarGroup("Export", items: [
                ("square.and.arrow.up", "Export"),
            ])

            divider

            toolbarGroup("Help", items: [
                ("questionmark.circle", "Help"),
            ])
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Toolbar group

    private func toolbarGroup(_ title: String, items: [(icon: String, label: String)]) -> some View {
        VStack(spacing: 1) {
            HStack(spacing: 6) {
                ForEach(items, id: \.icon) { item in
                    Button {
                        // Placeholder — not functional yet
                    } label: {
                        VStack(spacing: 1) {
                            Image(systemName: item.icon)
                                .font(.system(size: 14))
                                .frame(width: 20, height: 18)
                            Text(item.label)
                                .font(.system(size: 8))
                                .lineLimit(1)
                        }
                        .frame(minWidth: 32)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1, height: 40)
            .padding(.horizontal, 2)
    }
}
