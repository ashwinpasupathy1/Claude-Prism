// AxisRenderer.swift — Draws Prism-style open spines, tick marks,
// axis labels, and chart title using SwiftUI Canvas + Core Graphics.
//
// Extracted from RefractionApp into the RefractionRenderer Swift Package.

import SwiftUI

public enum AxisRenderer {

    /// Draw axes (spines, ticks, labels, title) into the canvas context.
    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        canvasSize: CGSize,
        spec: AxisSpec,
        style: StyleSpec,
        groups: [String]
    ) {
        let spineColor = Color(hex: "#222222")
        let lineWidth = spec.spineWidth

        // MARK: - Spines

        switch style.axisStyle {
        case "open":
            drawLine(in: context, from: plotRect.bottomLeft, to: plotRect.topLeft,
                     color: spineColor, width: lineWidth)
            drawLine(in: context, from: plotRect.bottomLeft, to: plotRect.bottomRight,
                     color: spineColor, width: lineWidth)

        case "closed":
            drawLine(in: context, from: plotRect.bottomLeft, to: plotRect.topLeft,
                     color: spineColor, width: lineWidth)
            drawLine(in: context, from: plotRect.bottomLeft, to: plotRect.bottomRight,
                     color: spineColor, width: lineWidth)
            drawLine(in: context, from: plotRect.topLeft, to: plotRect.topRight,
                     color: spineColor, width: lineWidth)
            drawLine(in: context, from: plotRect.bottomRight, to: plotRect.topRight,
                     color: spineColor, width: lineWidth)

        case "floating":
            let offset: CGFloat = 4
            drawLine(in: context,
                     from: CGPoint(x: plotRect.minX - offset, y: plotRect.maxY + offset),
                     to: CGPoint(x: plotRect.minX - offset, y: plotRect.minY),
                     color: spineColor, width: lineWidth)
            drawLine(in: context,
                     from: CGPoint(x: plotRect.minX - offset, y: plotRect.maxY + offset),
                     to: CGPoint(x: plotRect.maxX, y: plotRect.maxY + offset),
                     color: spineColor, width: lineWidth)

        default: // "none"
            break
        }

        // MARK: - Y-axis ticks

        let nYTicks = 5
        let fontSize = CGFloat(spec.fontSize)
        let tickLen: CGFloat = 5

        for i in 0...nYTicks {
            let fraction = CGFloat(i) / CGFloat(nYTicks)
            let y = plotRect.maxY - fraction * plotRect.height

            let tickStart: CGPoint
            let tickEnd: CGPoint

            switch spec.tickDirection {
            case "out":
                tickStart = CGPoint(x: plotRect.minX, y: y)
                tickEnd = CGPoint(x: plotRect.minX - tickLen, y: y)
            case "in":
                tickStart = CGPoint(x: plotRect.minX, y: y)
                tickEnd = CGPoint(x: plotRect.minX + tickLen, y: y)
            case "inout":
                tickStart = CGPoint(x: plotRect.minX - tickLen / 2, y: y)
                tickEnd = CGPoint(x: plotRect.minX + tickLen / 2, y: y)
            default:
                continue
            }

            drawLine(in: context, from: tickStart, to: tickEnd,
                     color: spineColor, width: 0.8)
        }

        // MARK: - X-axis category labels

        if !groups.isEmpty {
            let groupWidth = plotRect.width / CGFloat(groups.count)

            for (i, name) in groups.enumerated() {
                let x = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
                let y = plotRect.maxY

                if !spec.tickDirection.isEmpty {
                    let tickY: CGFloat
                    switch spec.tickDirection {
                    case "out":  tickY = y + tickLen
                    case "in":   tickY = y - tickLen
                    default:     tickY = y + tickLen
                    }
                    drawLine(in: context,
                             from: CGPoint(x: x, y: y),
                             to: CGPoint(x: x, y: tickY),
                             color: spineColor, width: 0.8)
                }

                let label = Text(name)
                    .font(.system(size: fontSize - 1))
                    .foregroundStyle(Color(hex: "#222222"))
                context.draw(label, at: CGPoint(x: x, y: y + tickLen + 12), anchor: .top)
            }
        }

        // MARK: - Axis labels

        if !spec.xLabel.isEmpty {
            let xLabelText = Text(spec.xLabel)
                .font(.system(size: fontSize))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(
                xLabelText,
                at: CGPoint(x: plotRect.midX, y: canvasSize.height - 8),
                anchor: .bottom
            )
        }

        if !spec.yLabel.isEmpty {
            var yContext = context
            let yLabelPos = CGPoint(x: 14, y: plotRect.midY)
            yContext.translateBy(x: yLabelPos.x, y: yLabelPos.y)
            yContext.rotate(by: .degrees(-90))

            let yLabelText = Text(spec.yLabel)
                .font(.system(size: fontSize))
                .foregroundStyle(Color(hex: "#222222"))
            yContext.draw(yLabelText, at: .zero, anchor: .center)
        }

        // MARK: - Title

        if !spec.title.isEmpty {
            let titleText = Text(spec.title)
                .font(.system(size: fontSize + 2, weight: .semibold))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(titleText, at: CGPoint(x: plotRect.midX, y: 16), anchor: .top)
        }
    }
}
