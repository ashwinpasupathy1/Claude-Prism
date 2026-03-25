// BeforeAfterRenderer.swift — Draws paired before/after data connected by lines.

import SwiftUI

public enum BeforeAfterRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard groups.count >= 2 else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)

        // Draw connecting lines between paired observations
        let beforeGroup = groups[0]
        let afterGroup = groups[1]
        let n = min(beforeGroup.values.raw.count, afterGroup.values.raw.count)

        let x1 = plotRect.minX + 0.5 * groupWidth
        let x2 = plotRect.minX + 1.5 * groupWidth

        for i in 0..<n {
            let y1 = yToCanvas(beforeGroup.values.raw[i], plotRect: plotRect, yRange: yRange)
            let y2 = yToCanvas(afterGroup.values.raw[i], plotRect: plotRect, yRange: yRange)

            // Line color based on direction
            let lineColor = afterGroup.values.raw[i] >= beforeGroup.values.raw[i]
                ? Color(hex: "#32936F").opacity(0.6)  // green for increase
                : Color(hex: "#E8453C").opacity(0.6)  // red for decrease

            drawLine(in: context,
                     from: CGPoint(x: x1, y: y1),
                     to: CGPoint(x: x2, y: y2),
                     color: lineColor, width: 1.0)
        }

        // Draw points for each group
        for (gi, group) in groups.prefix(2).enumerated() {
            let color = Color(hex: colorForIndex(gi, style: style))
            let centerX = plotRect.minX + (CGFloat(gi) + 0.5) * groupWidth

            for val in group.values.raw {
                let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)
                let r: CGFloat = 5
                let ptRect = CGRect(x: centerX - r, y: y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: ptRect), with: .color(color))
                context.stroke(Path(ellipseIn: ptRect), with: .color(color.opacity(0.8)), lineWidth: 0.5)
            }
        }
    }
}
