// StackedBarRenderer.swift — Draws stacked bar charts from the grouped data payload.
// Each category gets one bar with subgroup segments stacked vertically.

import SwiftUI

public enum StackedBarRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        spec: ChartSpec,
        style: StyleSpec
    ) {
        guard let data = spec.data else { return }

        guard let categoriesJSON = data["categories"]?.arrayValue,
              let subgroupsJSON = data["subgroups"]?.arrayValue,
              let meansJSON = data["means"]?.objectValue else {
            return
        }

        let categories = categoriesJSON.compactMap(\.stringValue)
        let subgroups = subgroupsJSON.compactMap(\.stringValue)
        guard !categories.isEmpty, !subgroups.isEmpty else { return }

        // Build means: subgroup -> [Double per category]
        var means: [String: [Double]] = [:]
        for sg in subgroups {
            if let vals = meansJSON[sg]?.doubleArray {
                means[sg] = vals
            }
        }

        // Compute Y range: max stacked total across categories
        var yMax: Double = 0
        for ci in 0..<categories.count {
            var total: Double = 0
            for sg in subgroups {
                if let m = means[sg], ci < m.count {
                    total += m[ci]
                }
            }
            yMax = max(yMax, total)
        }
        let yRange = (min: 0.0, max: yMax * 1.15)

        let catWidth = plotRect.width / CGFloat(categories.count)
        let barWidth = catWidth * CGFloat(style.barWidth)

        for (ci, _) in categories.enumerated() {
            let barX = plotRect.minX + CGFloat(ci) * catWidth + (catWidth - barWidth) / 2
            var stackBase: Double = 0

            for (si, sg) in subgroups.enumerated() {
                guard let m = means[sg], ci < m.count else { continue }
                let val = m[ci]
                let color = Color(hex: colorForIndex(si, style: style))

                let bottom = yToCanvas(stackBase, plotRect: plotRect, yRange: yRange)
                let top = yToCanvas(stackBase + val, plotRect: plotRect, yRange: yRange)

                let rect = CGRect(
                    x: barX,
                    y: min(top, bottom),
                    width: barWidth,
                    height: abs(bottom - top)
                )
                context.fill(Path(rect), with: .color(color.opacity(0.85)))
                context.stroke(Path(rect), with: .color(color), lineWidth: 0.5)

                stackBase += val
            }
        }

        // Category labels
        for (ci, cat) in categories.enumerated() {
            let x = plotRect.minX + (CGFloat(ci) + 0.5) * catWidth
            let label = Text(cat)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: x, y: plotRect.maxY + 14), anchor: .top)
        }
    }
}
