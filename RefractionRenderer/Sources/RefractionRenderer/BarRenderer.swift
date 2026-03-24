// BarRenderer.swift — Draws bar charts with error bars and jittered data
// points using SwiftUI Canvas + Core Graphics.
//
// Extracted from RefractionApp into the RefractionRenderer Swift Package.

import SwiftUI

public enum BarRenderer {

    /// Draw bars, error bars, and optional data points.
    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard !groups.isEmpty else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)
        let barFraction = CGFloat(style.barWidth)

        for (i, group) in groups.enumerated() {
            let color = Color(hex: colorForIndex(i, style: style))
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let barW = groupWidth * barFraction

            guard let mean = group.values.mean else { continue }

            let barTop = yToCanvas(mean, plotRect: plotRect, yRange: yRange)
            let barBottom = yToCanvas(max(yRange.min, 0), plotRect: plotRect, yRange: yRange)

            let barRect = CGRect(
                x: centerX - barW / 2,
                y: min(barTop, barBottom),
                width: barW,
                height: abs(barBottom - barTop)
            )
            context.fill(Path(barRect), with: .color(color.opacity(0.85)))

            let darkColor = color.opacity(1.0)
            context.stroke(Path(barRect), with: .color(darkColor), lineWidth: 0.8)

            let errorHalf = errorValue(for: group, errorType: style.errorType)
            if errorHalf > 0 {
                drawErrorBar(
                    in: context,
                    centerX: centerX,
                    mean: mean,
                    errorHalf: errorHalf,
                    plotRect: plotRect,
                    yRange: yRange,
                    capWidth: barW * 0.4
                )
            }

            if style.showPoints {
                drawDataPoints(
                    in: context,
                    values: group.values.raw,
                    centerX: centerX,
                    plotRect: plotRect,
                    yRange: yRange,
                    color: color,
                    pointSize: CGFloat(style.pointSize),
                    alpha: style.pointAlpha,
                    jitterWidth: barW * 0.3
                )
            }
        }
    }

    // MARK: - Error bars

    private static func drawErrorBar(
        in context: GraphicsContext,
        centerX: CGFloat,
        mean: Double,
        errorHalf: Double,
        plotRect: CGRect,
        yRange: (min: Double, max: Double),
        capWidth: CGFloat
    ) {
        let top = yToCanvas(mean + errorHalf, plotRect: plotRect, yRange: yRange)
        let bottom = yToCanvas(mean - errorHalf, plotRect: plotRect, yRange: yRange)
        let lineColor = Color(hex: "#222222")

        var vLine = Path()
        vLine.move(to: CGPoint(x: centerX, y: top))
        vLine.addLine(to: CGPoint(x: centerX, y: bottom))
        context.stroke(vLine, with: .color(lineColor), lineWidth: 1.0)

        var topCap = Path()
        topCap.move(to: CGPoint(x: centerX - capWidth / 2, y: top))
        topCap.addLine(to: CGPoint(x: centerX + capWidth / 2, y: top))
        context.stroke(topCap, with: .color(lineColor), lineWidth: 1.0)

        var bottomCap = Path()
        bottomCap.move(to: CGPoint(x: centerX - capWidth / 2, y: bottom))
        bottomCap.addLine(to: CGPoint(x: centerX + capWidth / 2, y: bottom))
        context.stroke(bottomCap, with: .color(lineColor), lineWidth: 1.0)
    }

    // MARK: - Data points

    private static func drawDataPoints(
        in context: GraphicsContext,
        values: [Double],
        centerX: CGFloat,
        plotRect: CGRect,
        yRange: (min: Double, max: Double),
        color: Color,
        pointSize: CGFloat,
        alpha: Double,
        jitterWidth: CGFloat
    ) {
        for (idx, val) in values.enumerated() {
            let jitter = jitterForIndex(idx, count: values.count, width: jitterWidth)
            let x = centerX + jitter
            let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)

            let pointRect = CGRect(
                x: x - pointSize / 2,
                y: y - pointSize / 2,
                width: pointSize,
                height: pointSize
            )

            context.fill(
                Path(ellipseIn: pointRect),
                with: .color(color.opacity(alpha))
            )
            context.stroke(
                Path(ellipseIn: pointRect),
                with: .color(color.opacity(min(alpha + 0.2, 1.0))),
                lineWidth: 0.5
            )
        }
    }
}
