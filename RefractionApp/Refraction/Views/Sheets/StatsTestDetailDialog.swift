// StatsTestDetailDialog.swift — Full mathematical description of a statistical test.
// Presented as a sheet from the Stats Wiki dialog.

import SwiftUI

struct StatsTestDetailDialog: View {

    let detail: StatsTestDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(detail.name)
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Aliases
                    if !detail.aliases.isEmpty {
                        Text("Also known as: \(detail.aliases.joined(separator: ", "))")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    // Hypotheses
                    sectionView(title: "Hypotheses", systemImage: "function") {
                        formulaText(detail.hypotheses)
                    }

                    // Test Statistic
                    sectionView(title: "Test Statistic", systemImage: "x.squareroot") {
                        formulaText(detail.testStatistic)
                    }

                    // Distribution
                    sectionView(title: "Distribution under H\u{2080}", systemImage: "chart.bar.xaxis") {
                        Text(detail.distribution)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Assumptions
                    sectionView(title: "Assumptions", systemImage: "checklist") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(detail.assumptions, id: \.self) { assumption in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("\u{2022}")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    Text(assumption)
                                        .font(.callout)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // When to Use
                    sectionView(title: "When to Use", systemImage: "checkmark.circle") {
                        Text(detail.whenToUse)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // When Not to Use
                    sectionView(title: "When Not to Use", systemImage: "xmark.circle") {
                        Text(detail.whenNotToUse)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Notes
                    if !detail.notes.isEmpty {
                        sectionView(title: "Notes", systemImage: "info.circle") {
                            Text(detail.notes)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // References
                    if !detail.references.isEmpty {
                        sectionView(title: "References", systemImage: "book") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(detail.references, id: \.self) { ref in
                                    Text(ref)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 600, height: 580)
    }

    // MARK: - Helpers

    private func sectionView<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formulaText(_ text: String) -> some View {
        Text(text)
            .font(.system(.callout, design: .monospaced))
            .fixedSize(horizontal: false, vertical: true)
    }
}
