// GroupedBarRenderer.swift — Draws grouped bar charts from the data payload.
// Reads categories, subgroups, means, and errors from spec.data.

import SwiftUI

public enum GroupedBarRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        spec: ChartSpec,
        style: StyleSpec
    ) {
        guard let data = spec.data else { return }

        // Extract from data payload
        guard let categoriesJSON = data["categories"]?.arrayValue,
              let subgroupsJSON = data["subgroups"]?.arrayValue,
              let meansJSON = data["means"]?.objectValue else {
            return
        }

        let categories = categoriesJSON.compactMap(\.stringValue)
        let subgroups = subgroupsJSON.compactMap(\.stringValue)
        guard !categories.isEmpty, !subgroups.isEmpty else { return }

        // Build means dict: subgroup -> [Double] (one per category)
        var means: [String: [Double]] = [:]
        for sg in subgroups {
            if let vals = meansJSON[sg]?.doubleArray {
                means[sg] = vals
            }
        }

        // Optionally extract errors
        var errors: [String: [Double]] = [:]
        if let errorsJSON = data["errors"]?.objectValue {
            for sg in subgroups {
                if let vals = errorsJSON[sg]?.doubleArray {
                    errors[sg] = vals
                }
            }
        }

        // Compute Y range
        var yMax: Double = 0
        for sg in subgroups {
            guard let m = means[sg] else { continue }
            let e = errors[sg] ?? Array(repeating: 0.0, count: m.count)
            for i in 0..<m.count {
                yMax = max(yMax, m[i] + e[i])
            }
        }
        let yRange = (min: 0.0, max: yMax * 1.15)

        let nCats = categories.count
        let nSubs = subgroups.count
        let catWidth = plotRect.width / CGFloat(nCats)
        let barWidth = catWidth * CGFloat(style.barWidth) / CGFloat(nSubs)
        let groupStart = catWidth * (1 - CGFloat(style.barWidth)) / 2

        for (ci, _) in categories.enumerated() {
            let catX = plotRect.minX + CGFloat(ci) * catWidth

            for (si, sg) in subgroups.enumerated() {
                guard let m = means[sg], ci < m.count else { continue }
                let mean = m[ci]
                let color = Color(hex: colorForIndex(si, style: style))

                let barX = catX + groupStart + CGFloat(si) * barWidth
                let barTop = yToCanvas(mean, plotRect: plotRect, yRange: yRange)
                let barBottom = yToCanvas(0, plotRect: plotRect, yRange: yRange)

                let rect = CGRect(
                    x: barX,
                    y: min(barTop, barBottom),
                    width: barWidth * 0.9,
                    height: abs(barBottom - barTop)
                )
                context.fill(Path(rect), with: .color(color.opacity(0.85)))
                context.stroke(Path(rect), with: .color(color), lineWidth: 0.8)

                // Error bars
                if let e = errors[sg], ci < e.count, e[ci] > 0 {
                    let centerX = barX + barWidth * 0.45
                    let capW = barWidth * 0.3
                    let top = yToCanvas(mean + e[ci], plotRect: plotRect, yRange: yRange)
                    let lineColor = Color(hex: "#222222")

                    drawLine(in: context,
                             from: CGPoint(x: centerX, y: barTop),
                             to: CGPoint(x: centerX, y: top),
                             color: lineColor, width: 1.0)
                    drawLine(in: context,
                             from: CGPoint(x: centerX - capW / 2, y: top),
                             to: CGPoint(x: centerX + capW / 2, y: top),
                             color: lineColor, width: 1.0)
                }
            }
        }

        // Draw category labels
        for (ci, cat) in categories.enumerated() {
            let x = plotRect.minX + (CGFloat(ci) + 0.5) * catWidth
            let label = Text(cat)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: x, y: plotRect.maxY + 14), anchor: .top)
        }
    }
}
