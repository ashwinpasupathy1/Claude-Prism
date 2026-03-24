import Testing
@testable import RefractionRenderer

@Suite("RenderTheme tests")
struct RenderThemeTests {

    @Test("allBuiltIn contains exactly 5 themes")
    func allBuiltInCount() {
        #expect(RenderTheme.allBuiltIn.count == 5)
    }

    @Test("Prism theme has correct defaults")
    func prismDefaults() {
        let t = RenderTheme.prism
        #expect(t.name == "Prism")
        #expect(t.spineStyle == .open)
        #expect(t.tickDirection == .outward)
        #expect(t.gridStyle == .none)
    }

    @Test("ggplot2 theme has none spines and full grid")
    func ggplot2Style() {
        let t = RenderTheme.ggplot2
        #expect(t.name == "ggplot2")
        #expect(t.spineStyle == .none)
        #expect(t.tickDirection == .none)
        #expect(t.gridStyle == .full)
    }

    @Test("Dark theme has dark background")
    func darkBackground() {
        let t = RenderTheme.dark
        #expect(t.name == "Dark")
        #expect(t.spineStyle == .open)
        #expect(t.gridStyle == .horizontal)
    }

    @Test("Classic theme has closed spines and inward ticks")
    func classicStyle() {
        let t = RenderTheme.classic
        #expect(t.spineStyle == .closed)
        #expect(t.tickDirection == .inward)
    }

    @Test("Minimal theme has no spines and horizontal grid")
    func minimalStyle() {
        let t = RenderTheme.minimal
        #expect(t.spineStyle == .none)
        #expect(t.gridStyle == .horizontal)
    }

    @Test("All theme names are unique")
    func uniqueNames() {
        let names = RenderTheme.allBuiltIn.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test("StyleSpec default colors match Prism palette")
    func defaultColors() {
        #expect(StyleSpec.defaultColors.count == 10)
        #expect(StyleSpec.defaultColors[0] == "#E8453C")
        #expect(StyleSpec.defaultColors[1] == "#2274A5")
    }

    @Test("ChartSpec memberwise initializer works")
    func chartSpecInit() {
        let spec = ChartSpec(chartType: "bar")
        #expect(spec.chartType == "bar")
        #expect(spec.groups.isEmpty)
        #expect(spec.brackets.isEmpty)
    }

    @Test("GroupData is identifiable by name")
    func groupDataId() {
        let g = GroupData(name: "Test", values: ValuesData(), color: "#FF0000")
        #expect(g.id == "Test")
    }
}
