// FormatAxesSettings.swift — Renderer-only axis formatting overrides for a graph sheet.
// These settings are applied by the SwiftUI renderer on top of the ChartSpec data.
// Nothing here triggers an engine call — it's purely visual axis formatting.

import Foundation
import SwiftUI

@Observable
final class FormatAxesSettings: Codable {

    // MARK: - Enums

    enum OriginMode: String, Codable, CaseIterable, Identifiable {
        case automatic
        case manual

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum FrameStyle: String, Codable, CaseIterable, Identifiable {
        case noFrame = "no_frame"
        case plain
        case shadow

        var id: String { rawValue }

        var label: String {
            switch self {
            case .noFrame: return "No Frame"
            case .plain:   return "Plain"
            case .shadow:  return "Shadow"
            }
        }
    }

    enum HideAxes: String, Codable, CaseIterable, Identifiable {
        case showBoth = "show_both"
        case hideX = "hide_x"
        case hideY = "hide_y"
        case hideBoth = "hide_both"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .showBoth: return "Show Both"
            case .hideX:    return "Hide X"
            case .hideY:    return "Hide Y"
            case .hideBoth: return "Hide Both"
            }
        }
    }

    enum GridLineStyle: String, Codable, CaseIterable, Identifiable {
        case none
        case solid
        case dashed
        case dotted

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum TickDir: String, Codable, CaseIterable, Identifiable {
        case out
        case `in` = "in"
        case both
        case none

        var id: String { rawValue }

        var label: String {
            switch self {
            case .out:  return "Out"
            case .in:   return "In"
            case .both: return "Both"
            case .none: return "None"
            }
        }
    }

    enum ScaleType: String, Codable, CaseIterable, Identifiable {
        case linear
        case log

        var id: String { rawValue }

        var label: String {
            switch self {
            case .linear: return "Linear"
            case .log:    return "Log₁₀"
            }
        }
    }

    // MARK: - Frame and Origin

    var originMode: OriginMode = .automatic
    var yIntersectsXAt: Double = 0
    var xIntersectsYAt: Double = 0
    var chartWidth: Double = 3.0
    var chartHeight: Double = 2.0
    var axisThickness: Double = 1.0
    var axisColor: String = "#000000"
    var plotAreaColor: String = "clear"
    var pageBackground: String = "clear"
    var frameStyle: FrameStyle = .noFrame
    var hideAxes: HideAxes = .showBoth
    var majorGrid: GridLineStyle = .none
    var majorGridColor: String = "#CCCCCC"
    var majorGridThickness: Double = 1.0
    var minorGrid: GridLineStyle = .none
    var minorGridColor: String = "#EEEEEE"
    var minorGridThickness: Double = 0.5

    // MARK: - X Axis

    var xAxisTitle: String = ""
    var xAxisTitleFontSize: Double = 12
    var xAxisTickDirection: TickDir = .out
    var xAxisTickLength: Double = 5
    var xAxisLabelFontSize: Double = 10
    var xAxisLabelRotation: Double = 0

    // MARK: - Left Y Axis

    var yAxisTitle: String = ""
    var yAxisTitleFontSize: Double = 12
    var yAxisTickDirection: TickDir = .out
    var yAxisTickLength: Double = 5
    var yAxisLabelFontSize: Double = 10
    var yAxisAutoRange: Bool = true
    var yAxisMin: Double = 0
    var yAxisMax: Double = 10
    var yAxisTickInterval: Double = 0
    var yAxisScale: ScaleType = .linear

    // MARK: - Titles & Fonts

    var chartTitle: String = ""
    var chartTitleFontSize: Double = 14
    var globalFontName: String = "Helvetica"

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case originMode, yIntersectsXAt, xIntersectsYAt
        case chartWidth, chartHeight
        case axisThickness, axisColor, plotAreaColor, pageBackground
        case frameStyle, hideAxes
        case majorGrid, majorGridColor, majorGridThickness
        case minorGrid, minorGridColor, minorGridThickness
        case xAxisTitle, xAxisTitleFontSize
        case xAxisTickDirection, xAxisTickLength
        case xAxisLabelFontSize, xAxisLabelRotation
        case yAxisTitle, yAxisTitleFontSize
        case yAxisTickDirection, yAxisTickLength
        case yAxisLabelFontSize, yAxisAutoRange
        case yAxisMin, yAxisMax, yAxisTickInterval, yAxisScale
        case chartTitle, chartTitleFontSize, globalFontName
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Frame and Origin
        originMode = (try? c.decode(OriginMode.self, forKey: .originMode)) ?? .automatic
        yIntersectsXAt = (try? c.decode(Double.self, forKey: .yIntersectsXAt)) ?? 0
        xIntersectsYAt = (try? c.decode(Double.self, forKey: .xIntersectsYAt)) ?? 0
        chartWidth = (try? c.decode(Double.self, forKey: .chartWidth)) ?? 3.0
        chartHeight = (try? c.decode(Double.self, forKey: .chartHeight)) ?? 2.0
        axisThickness = (try? c.decode(Double.self, forKey: .axisThickness)) ?? 1.0
        axisColor = (try? c.decode(String.self, forKey: .axisColor)) ?? "#000000"
        plotAreaColor = (try? c.decode(String.self, forKey: .plotAreaColor)) ?? "clear"
        pageBackground = (try? c.decode(String.self, forKey: .pageBackground)) ?? "clear"
        frameStyle = (try? c.decode(FrameStyle.self, forKey: .frameStyle)) ?? .noFrame
        hideAxes = (try? c.decode(HideAxes.self, forKey: .hideAxes)) ?? .showBoth
        majorGrid = (try? c.decode(GridLineStyle.self, forKey: .majorGrid)) ?? .none
        majorGridColor = (try? c.decode(String.self, forKey: .majorGridColor)) ?? "#CCCCCC"
        majorGridThickness = (try? c.decode(Double.self, forKey: .majorGridThickness)) ?? 1.0
        minorGrid = (try? c.decode(GridLineStyle.self, forKey: .minorGrid)) ?? .none
        minorGridColor = (try? c.decode(String.self, forKey: .minorGridColor)) ?? "#EEEEEE"
        minorGridThickness = (try? c.decode(Double.self, forKey: .minorGridThickness)) ?? 0.5

        // X Axis
        xAxisTitle = (try? c.decode(String.self, forKey: .xAxisTitle)) ?? ""
        xAxisTitleFontSize = (try? c.decode(Double.self, forKey: .xAxisTitleFontSize)) ?? 12
        xAxisTickDirection = (try? c.decode(TickDir.self, forKey: .xAxisTickDirection)) ?? .out
        xAxisTickLength = (try? c.decode(Double.self, forKey: .xAxisTickLength)) ?? 5
        xAxisLabelFontSize = (try? c.decode(Double.self, forKey: .xAxisLabelFontSize)) ?? 10
        xAxisLabelRotation = (try? c.decode(Double.self, forKey: .xAxisLabelRotation)) ?? 0

        // Left Y Axis
        yAxisTitle = (try? c.decode(String.self, forKey: .yAxisTitle)) ?? ""
        yAxisTitleFontSize = (try? c.decode(Double.self, forKey: .yAxisTitleFontSize)) ?? 12
        yAxisTickDirection = (try? c.decode(TickDir.self, forKey: .yAxisTickDirection)) ?? .out
        yAxisTickLength = (try? c.decode(Double.self, forKey: .yAxisTickLength)) ?? 5
        yAxisLabelFontSize = (try? c.decode(Double.self, forKey: .yAxisLabelFontSize)) ?? 10
        yAxisAutoRange = (try? c.decode(Bool.self, forKey: .yAxisAutoRange)) ?? true
        yAxisMin = (try? c.decode(Double.self, forKey: .yAxisMin)) ?? 0
        yAxisMax = (try? c.decode(Double.self, forKey: .yAxisMax)) ?? 10
        yAxisTickInterval = (try? c.decode(Double.self, forKey: .yAxisTickInterval)) ?? 0
        yAxisScale = (try? c.decode(ScaleType.self, forKey: .yAxisScale)) ?? .linear

        // Titles & Fonts
        chartTitle = (try? c.decode(String.self, forKey: .chartTitle)) ?? ""
        chartTitleFontSize = (try? c.decode(Double.self, forKey: .chartTitleFontSize)) ?? 14
        globalFontName = (try? c.decode(String.self, forKey: .globalFontName)) ?? "Helvetica"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        // Frame and Origin
        try c.encode(originMode, forKey: .originMode)
        try c.encode(yIntersectsXAt, forKey: .yIntersectsXAt)
        try c.encode(xIntersectsYAt, forKey: .xIntersectsYAt)
        try c.encode(chartWidth, forKey: .chartWidth)
        try c.encode(chartHeight, forKey: .chartHeight)
        try c.encode(axisThickness, forKey: .axisThickness)
        try c.encode(axisColor, forKey: .axisColor)
        try c.encode(plotAreaColor, forKey: .plotAreaColor)
        try c.encode(pageBackground, forKey: .pageBackground)
        try c.encode(frameStyle, forKey: .frameStyle)
        try c.encode(hideAxes, forKey: .hideAxes)
        try c.encode(majorGrid, forKey: .majorGrid)
        try c.encode(majorGridColor, forKey: .majorGridColor)
        try c.encode(majorGridThickness, forKey: .majorGridThickness)
        try c.encode(minorGrid, forKey: .minorGrid)
        try c.encode(minorGridColor, forKey: .minorGridColor)
        try c.encode(minorGridThickness, forKey: .minorGridThickness)

        // X Axis
        try c.encode(xAxisTitle, forKey: .xAxisTitle)
        try c.encode(xAxisTitleFontSize, forKey: .xAxisTitleFontSize)
        try c.encode(xAxisTickDirection, forKey: .xAxisTickDirection)
        try c.encode(xAxisTickLength, forKey: .xAxisTickLength)
        try c.encode(xAxisLabelFontSize, forKey: .xAxisLabelFontSize)
        try c.encode(xAxisLabelRotation, forKey: .xAxisLabelRotation)

        // Left Y Axis
        try c.encode(yAxisTitle, forKey: .yAxisTitle)
        try c.encode(yAxisTitleFontSize, forKey: .yAxisTitleFontSize)
        try c.encode(yAxisTickDirection, forKey: .yAxisTickDirection)
        try c.encode(yAxisTickLength, forKey: .yAxisTickLength)
        try c.encode(yAxisLabelFontSize, forKey: .yAxisLabelFontSize)
        try c.encode(yAxisAutoRange, forKey: .yAxisAutoRange)
        try c.encode(yAxisMin, forKey: .yAxisMin)
        try c.encode(yAxisMax, forKey: .yAxisMax)
        try c.encode(yAxisTickInterval, forKey: .yAxisTickInterval)
        try c.encode(yAxisScale, forKey: .yAxisScale)

        // Titles & Fonts
        try c.encode(chartTitle, forKey: .chartTitle)
        try c.encode(chartTitleFontSize, forKey: .chartTitleFontSize)
        try c.encode(globalFontName, forKey: .globalFontName)
    }
}
