// RenderTheme.swift — Built-in rendering themes for chart visual styles.
// Provides Prism, ggplot2, Minimal, Classic, and Dark themes.

import SwiftUI

public struct RenderTheme {
    public let name: String
    public let backgroundColor: Color
    public let gridColor: Color
    public let textColor: Color
    public let spineStyle: SpineStyle
    public let tickDirection: TickDirection
    public let gridStyle: GridStyle

    public enum SpineStyle { case open, closed, floating, none }
    public enum TickDirection { case outward, inward, both, none }
    public enum GridStyle { case none, horizontal, full }

    public init(
        name: String,
        backgroundColor: Color,
        gridColor: Color,
        textColor: Color,
        spineStyle: SpineStyle,
        tickDirection: TickDirection,
        gridStyle: GridStyle
    ) {
        self.name = name
        self.backgroundColor = backgroundColor
        self.gridColor = gridColor
        self.textColor = textColor
        self.spineStyle = spineStyle
        self.tickDirection = tickDirection
        self.gridStyle = gridStyle
    }

    public static let prism = RenderTheme(
        name: "Prism",
        backgroundColor: .white,
        gridColor: .clear,
        textColor: .black,
        spineStyle: .open,
        tickDirection: .outward,
        gridStyle: .none
    )

    public static let ggplot2 = RenderTheme(
        name: "ggplot2",
        backgroundColor: Color(hex: "#E5E5E5"),
        gridColor: .white,
        textColor: .black,
        spineStyle: .none,
        tickDirection: .none,
        gridStyle: .full
    )

    public static let minimal = RenderTheme(
        name: "Minimal",
        backgroundColor: .white,
        gridColor: Color(hex: "#EEEEEE"),
        textColor: .black,
        spineStyle: .none,
        tickDirection: .none,
        gridStyle: .horizontal
    )

    public static let classic = RenderTheme(
        name: "Classic",
        backgroundColor: .white,
        gridColor: Color(hex: "#CCCCCC"),
        textColor: .black,
        spineStyle: .closed,
        tickDirection: .inward,
        gridStyle: .full
    )

    public static let dark = RenderTheme(
        name: "Dark",
        backgroundColor: Color(hex: "#1E1E1E"),
        gridColor: Color(hex: "#333333"),
        textColor: .white,
        spineStyle: .open,
        tickDirection: .outward,
        gridStyle: .horizontal
    )

    public static let allBuiltIn: [RenderTheme] = [.prism, .ggplot2, .minimal, .classic, .dark]
}
