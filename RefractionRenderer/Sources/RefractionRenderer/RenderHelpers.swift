// RenderHelpers.swift — Shared rendering helpers: Color(hex:) extension,
// coordinate mapping, and CGRect convenience accessors.

import SwiftUI

// MARK: - Color from hex string

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Coordinate mapping

/// Map a data Y value to canvas Y coordinate (top = high values).
public func yToCanvas(
    _ value: Double,
    plotRect: CGRect,
    yRange: (min: Double, max: Double)
) -> CGFloat {
    guard yRange.max > yRange.min else { return plotRect.midY }
    let fraction = (value - yRange.min) / (yRange.max - yRange.min)
    return plotRect.maxY - CGFloat(fraction) * plotRect.height
}

/// Deterministic jitter for point index, spreading points within a given width.
public func jitterForIndex(_ index: Int, count: Int, width: CGFloat) -> CGFloat {
    guard count > 1 else { return 0 }
    let base = CGFloat(index) / CGFloat(count - 1) - 0.5
    let hash = Double((index * 2654435761) & 0xFFFF) / 65535.0 - 0.5
    return (base * 0.6 + CGFloat(hash) * 0.4) * width
}

/// Get the color hex string for a group index from the style spec.
public func colorForIndex(_ index: Int, style: StyleSpec) -> String {
    if index < style.colors.count {
        return style.colors[index]
    }
    return StyleSpec.defaultColors[index % StyleSpec.defaultColors.count]
}

/// Get the error bar half-width for a group based on the error type.
public func errorValue(for group: GroupData, errorType: String) -> Double {
    switch errorType {
    case "sem": return group.values.sem ?? 0
    case "sd":  return group.values.sd ?? 0
    case "ci95": return group.values.ci95 ?? 0
    default: return group.values.sem ?? 0
    }
}

/// Compute the Y axis range from group data.
public func computeYRange(
    groups: [GroupData],
    errorType: String = "sem"
) -> (min: Double, max: Double) {
    var allMax: Double = 0
    var allMin: Double = 0

    for g in groups {
        guard let mean = g.values.mean else { continue }
        let err = errorValue(for: g, errorType: errorType)
        allMax = Swift.max(allMax, mean + err)
        allMin = Swift.min(allMin, mean - err)

        for v in g.values.raw {
            allMax = Swift.max(allMax, v)
            allMin = Swift.min(allMin, v)
        }
    }

    let padding = (allMax - allMin) * 0.1
    return (min: Swift.min(allMin, 0), max: allMax + padding)
}

// MARK: - CGRect convenience

public extension CGRect {
    var topLeft: CGPoint { CGPoint(x: minX, y: minY) }
    var topRight: CGPoint { CGPoint(x: maxX, y: minY) }
    var bottomLeft: CGPoint { CGPoint(x: minX, y: maxY) }
    var bottomRight: CGPoint { CGPoint(x: maxX, y: maxY) }
}

// MARK: - Line drawing helper

/// Draw a line between two points in a graphics context.
public func drawLine(
    in context: GraphicsContext,
    from: CGPoint, to: CGPoint,
    color: Color, width: CGFloat
) {
    var path = Path()
    path.move(to: from)
    path.addLine(to: to)
    context.stroke(path, with: .color(color), lineWidth: width)
}
