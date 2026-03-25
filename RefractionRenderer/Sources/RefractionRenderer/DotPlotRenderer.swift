// DotPlotRenderer.swift — Draws jittered dot plots with mean/median marker lines.

import SwiftUI

public enum DotPlotRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard !groups.isEmpty else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)
        let pointSize: CGFloat = CGFloat(style.pointSize)

        for (i, group) in groups.enumerated() {
            let color = Color(hex: colorForIndex(i, style: style))
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let jitterW = groupWidth * 0.3

            // Draw jittered points
            for (idx, val) in group.values.raw.enumerated() {
                let jitter = jitterForIndex(idx, count: group.values.raw.count, width: jitterW)
                let x = centerX + jitter
                let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)

                let ptRect = CGRect(
                    x: x - pointSize / 2,
                    y: y - pointSize / 2,
                    width: pointSize,
                    height: pointSize
                )
                context.fill(Path(ellipseIn: ptRect), with: .color(color.opacity(0.8)))
                context.stroke(Path(ellipseIn: ptRect), with: .color(color), lineWidth: 0.5)
            }

            // Draw mean line
            if let mean = group.values.mean {
                let y = yToCanvas(mean, plotRect: plotRect, yRange: yRange)
                let lineW = groupWidth * 0.35
                drawLine(in: context,
                         from: CGPoint(x: centerX - lineW, y: y),
                         to: CGPoint(x: centerX + lineW, y: y),
                         color: Color(hex: "#222222"), width: 2.0)
            }
        }
    }
}
