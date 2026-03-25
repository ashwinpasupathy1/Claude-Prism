// ScatterRenderer.swift — Draws scatter plots.
// Supports both XY data (from dedicated analyzer with x/y coordinates)
// and category data (from generic path with groups).

import SwiftUI

public enum ScatterRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec,
        data: [String: JSONValue]? = nil
    ) {
        // Prefer XY data payload from dedicated analyzer
        if let data = data, let seriesJSON = data["series"]?.arrayValue {
            drawXY(in: context, plotRect: plotRect, data: data, series: seriesJSON, style: style)
            return
        }

        // Fallback: category scatter from generic groups
        drawCategory(in: context, plotRect: plotRect, groups: groups, style: style)
    }

    // MARK: - XY scatter (dedicated analyzer)

    private static func drawXY(
        in context: GraphicsContext,
        plotRect: CGRect,
        data: [String: JSONValue],
        series: [JSONValue],
        style: StyleSpec
    ) {
        // Compute X and Y ranges from all points
        var xMin = Double.infinity, xMax = -Double.infinity
        var yMin = Double.infinity, yMax = -Double.infinity

        var parsedSeries: [(name: String, points: [(x: Double, y: Double, yRaw: [Double])], color: String)] = []

        for (si, seriesVal) in series.enumerated() {
            guard let obj = seriesVal.objectValue,
                  let name = obj["name"]?.stringValue,
                  let pointsJSON = obj["points"]?.arrayValue else { continue }

            let color = obj["color"]?.stringValue ?? StyleSpec.defaultColors[si % StyleSpec.defaultColors.count]
            var points: [(x: Double, y: Double, yRaw: [Double])] = []

            for pVal in pointsJSON {
                guard let pObj = pVal.objectValue,
                      let x = pObj["x"]?.doubleValue,
                      let yMean = pObj["y_mean"]?.doubleValue else { continue }

                let yRaw = pObj["y_raw"]?.doubleArray ?? [yMean]

                xMin = min(xMin, x)
                xMax = max(xMax, x)
                yMin = min(yMin, yMean)
                yMax = max(yMax, yMean)
                for yr in yRaw {
                    yMin = min(yMin, yr)
                    yMax = max(yMax, yr)
                }

                points.append((x, yMean, yRaw))
            }

            parsedSeries.append((name, points, color))
        }

        guard xMax > xMin, yMax > yMin else { return }

        // Add padding
        let xPad = (xMax - xMin) * 0.05
        let yPad = (yMax - yMin) * 0.1
        let xRange = (min: xMin - xPad, max: xMax + xPad)
        let yRange = (min: min(yMin - yPad, 0), max: yMax + yPad)

        // Draw each series
        for series in parsedSeries {
            let color = Color(hex: series.color)
            let pointSize: CGFloat = CGFloat(style.pointSize)

            for pt in series.points {
                let cx = xToCanvas(pt.x, plotRect: plotRect, xRange: xRange)
                let cy = yToCanvas(pt.y, plotRect: plotRect, yRange: yRange)

                // Draw individual replicates if more than 1
                if pt.yRaw.count > 1 {
                    for yr in pt.yRaw {
                        let ry = yToCanvas(yr, plotRect: plotRect, yRange: yRange)
                        let r = pointSize * 0.7
                        let rect = CGRect(x: cx - r/2, y: ry - r/2, width: r, height: r)
                        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.4)))
                    }
                }

                // Draw mean point
                let rect = CGRect(x: cx - pointSize/2, y: cy - pointSize/2,
                                  width: pointSize, height: pointSize)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.9)))
                context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 0.5)
            }
        }

        // Draw X axis tick labels
        let nXTicks = min(Int(xMax - xMin) + 1, 10)
        let xStep = (xMax - xMin) / Double(max(nXTicks - 1, 1))
        for i in 0..<nXTicks {
            let val = xMin + Double(i) * xStep
            let cx = xToCanvas(val, plotRect: plotRect, xRange: xRange)
            let label = Text(formatNumber(val))
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: cx, y: plotRect.maxY + 14), anchor: .top)
        }
    }

    // MARK: - Category scatter (fallback)

    private static func drawCategory(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard !groups.isEmpty else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)
        let pointSize = CGFloat(style.pointSize)

        for (i, group) in groups.enumerated() {
            let color = Color(hex: colorForIndex(i, style: style))
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let jitterW = groupWidth * 0.4

            for (idx, val) in group.values.raw.enumerated() {
                let jitter = jitterForIndex(idx, count: group.values.raw.count, width: jitterW)
                let x = centerX + jitter
                let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)

                let ptRect = CGRect(x: x - pointSize/2, y: y - pointSize/2,
                                    width: pointSize, height: pointSize)
                context.fill(Path(ellipseIn: ptRect), with: .color(color.opacity(0.8)))
                context.stroke(Path(ellipseIn: ptRect), with: .color(color), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Helpers

    private static func formatNumber(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e6 { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}

// MARK: - X coordinate mapping

public func xToCanvas(
    _ value: Double,
    plotRect: CGRect,
    xRange: (min: Double, max: Double)
) -> CGFloat {
    guard xRange.max > xRange.min else { return plotRect.midX }
    let fraction = (value - xRange.min) / (xRange.max - xRange.min)
    return plotRect.minX + CGFloat(fraction) * plotRect.width
}
