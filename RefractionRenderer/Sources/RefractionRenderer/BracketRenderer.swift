// BracketRenderer.swift — Draws significance brackets between groups.
// Brackets show statistical comparison results (e.g. "***", "ns", "p=0.023")
// with proper vertical stacking to avoid overlap.
//
// Extracted from RefractionApp into the RefractionRenderer Swift Package.

import SwiftUI

public enum BracketRenderer {

    /// Vertical spacing between stacked brackets.
    private static let bracketSpacing: CGFloat = 18

    /// Height of the vertical drops at each end of a bracket.
    private static let dropHeight: CGFloat = 6

    /// Padding above the tallest bar/error bar to the first bracket.
    private static let topPadding: CGFloat = 12

    /// Draw all significance brackets.
    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        brackets: [Bracket],
        groupCount: Int,
        style: StyleSpec
    ) {
        guard groupCount > 0, !brackets.isEmpty else { return }

        let groupWidth = plotRect.width / CGFloat(groupCount)
        let bracketColor = Color(hex: "#222222")

        let sorted = brackets.sorted { $0.stackingOrder < $1.stackingOrder }

        for bracket in sorted {
            let leftIndex = bracket.leftIndex
            let rightIndex = bracket.rightIndex

            guard leftIndex >= 0, leftIndex < groupCount,
                  rightIndex >= 0, rightIndex < groupCount else { continue }

            let leftX = plotRect.minX + (CGFloat(leftIndex) + 0.5) * groupWidth
            let rightX = plotRect.minX + (CGFloat(rightIndex) + 0.5) * groupWidth

            let bracketY = plotRect.minY - topPadding - CGFloat(bracket.stackingOrder) * bracketSpacing

            // Left vertical drop
            var leftDrop = Path()
            leftDrop.move(to: CGPoint(x: leftX, y: bracketY + dropHeight))
            leftDrop.addLine(to: CGPoint(x: leftX, y: bracketY))
            context.stroke(leftDrop, with: .color(bracketColor), lineWidth: 0.8)

            // Horizontal bar
            var hBar = Path()
            hBar.move(to: CGPoint(x: leftX, y: bracketY))
            hBar.addLine(to: CGPoint(x: rightX, y: bracketY))
            context.stroke(hBar, with: .color(bracketColor), lineWidth: 0.8)

            // Right vertical drop
            var rightDrop = Path()
            rightDrop.move(to: CGPoint(x: rightX, y: bracketY))
            rightDrop.addLine(to: CGPoint(x: rightX, y: bracketY + dropHeight))
            context.stroke(rightDrop, with: .color(bracketColor), lineWidth: 0.8)

            // Label
            let midX = (leftX + rightX) / 2
            let labelY = bracketY - 3

            let labelText = Text(bracket.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(bracketColor)
            context.draw(labelText, at: CGPoint(x: midX, y: labelY), anchor: .bottom)
        }
    }
}
