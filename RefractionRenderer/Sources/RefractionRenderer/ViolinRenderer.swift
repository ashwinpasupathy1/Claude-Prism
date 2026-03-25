// ViolinRenderer.swift — Draws violin plots with KDE shapes and inner box plots.
// KDE is computed client-side from raw values using a Gaussian kernel.

import SwiftUI

public enum ViolinRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard !groups.isEmpty else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)

        for (i, group) in groups.enumerated() {
            let color = Color(hex: colorForIndex(i, style: style))
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let halfWidth = groupWidth * 0.35

            let values = group.values.raw
            guard values.count >= 4 else {
                // Too few: draw as dots
                for (idx, val) in values.enumerated() {
                    let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)
                    let j = jitterForIndex(idx, count: values.count, width: 10)
                    let r: CGFloat = 4
                    let pt = CGRect(x: centerX + j - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: pt), with: .color(color.opacity(0.8)))
                }
                continue
            }

            // Compute KDE
            let sorted = values.sorted()
            let lo = sorted.first!
            let hi = sorted.last!
            let range = hi - lo
            guard range > 0 else { continue }

            // Bandwidth (Silverman's rule)
            let n = Double(values.count)
            let sd = sqrt(values.map { ($0 - values.reduce(0, +) / n) * ($0 - values.reduce(0, +) / n) }.reduce(0, +) / n)
            let bw = max(1.06 * sd * pow(n, -0.2), range * 0.05)

            let nPoints = 50
            var kdePoints: [(y: CGFloat, density: CGFloat)] = []
            var maxDensity: CGFloat = 0

            for step in 0..<nPoints {
                let frac = Double(step) / Double(nPoints - 1)
                let val = lo + frac * range
                var density: Double = 0
                for v in values {
                    let z = (val - v) / bw
                    density += exp(-0.5 * z * z)
                }
                density /= (n * bw * sqrt(2 * .pi))
                let cy = yToCanvas(val, plotRect: plotRect, yRange: yRange)
                kdePoints.append((cy, CGFloat(density)))
                maxDensity = max(maxDensity, CGFloat(density))
            }

            guard maxDensity > 0 else { continue }

            // Draw mirrored KDE shape
            var violinPath = Path()
            // Right side
            for (idx, kp) in kdePoints.enumerated() {
                let dx = (kp.density / maxDensity) * halfWidth
                let pt = CGPoint(x: centerX + dx, y: kp.y)
                if idx == 0 { violinPath.move(to: pt) }
                else { violinPath.addLine(to: pt) }
            }
            // Left side (reversed)
            for kp in kdePoints.reversed() {
                let dx = (kp.density / maxDensity) * halfWidth
                violinPath.addLine(to: CGPoint(x: centerX - dx, y: kp.y))
            }
            violinPath.closeSubpath()

            context.fill(violinPath, with: .color(color.opacity(0.3)))
            context.stroke(violinPath, with: .color(color), lineWidth: 1.0)

            // Inner mini box plot
            let q1 = percentile(sorted, p: 0.25)
            let median = percentile(sorted, p: 0.50)
            let q3 = percentile(sorted, p: 0.75)
            let boxW: CGFloat = halfWidth * 0.3

            let yq1 = yToCanvas(q1, plotRect: plotRect, yRange: yRange)
            let yq3 = yToCanvas(q3, plotRect: plotRect, yRange: yRange)
            let ymed = yToCanvas(median, plotRect: plotRect, yRange: yRange)

            let boxRect = CGRect(
                x: centerX - boxW / 2,
                y: min(yq1, yq3),
                width: boxW,
                height: abs(yq1 - yq3)
            )
            context.fill(Path(boxRect), with: .color(Color(hex: "#222222").opacity(0.4)))

            // Median dot
            let medR: CGFloat = 3
            let medPt = CGRect(x: centerX - medR, y: ymed - medR, width: medR * 2, height: medR * 2)
            context.fill(Path(ellipseIn: medPt), with: .color(.white))
        }
    }

    private static func percentile(_ sorted: [Double], p: Double) -> Double {
        let n = Double(sorted.count)
        let idx = p * (n - 1)
        let lo = Int(idx)
        let hi = min(lo + 1, sorted.count - 1)
        let frac = idx - Double(lo)
        return sorted[lo] * (1 - frac) + sorted[hi] * frac
    }
}
