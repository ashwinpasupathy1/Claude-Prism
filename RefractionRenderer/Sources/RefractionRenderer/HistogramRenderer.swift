// HistogramRenderer.swift — Draws histograms with auto-binned adjacent bars.

import SwiftUI

public enum HistogramRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        // Combine all raw values from all groups
        let allValues = groups.flatMap { $0.values.raw }
        guard allValues.count >= 2 else { return }

        let sorted = allValues.sorted()
        let lo = sorted.first!
        let hi = sorted.last!
        guard hi > lo else { return }

        // Sturges rule for bin count
        let nBins = max(Int(ceil(log2(Double(allValues.count)))) + 1, 5)
        let binWidth = (hi - lo) / Double(nBins)

        // Count values per bin
        var counts = [Int](repeating: 0, count: nBins)
        for v in allValues {
            var bin = Int((v - lo) / binWidth)
            if bin >= nBins { bin = nBins - 1 }
            counts[bin] += 1
        }

        let maxCount = counts.max() ?? 1
        let barW = plotRect.width / CGFloat(nBins)
        let color = Color(hex: colorForIndex(0, style: style))

        for (i, count) in counts.enumerated() {
            let fraction = CGFloat(count) / CGFloat(maxCount)
            let barHeight = fraction * plotRect.height
            let x = plotRect.minX + CGFloat(i) * barW
            let y = plotRect.maxY - barHeight

            let rect = CGRect(x: x, y: y, width: barW, height: barHeight)
            context.fill(Path(rect), with: .color(color.opacity(0.7)))
            context.stroke(Path(rect), with: .color(color), lineWidth: 0.5)
        }
    }
}
