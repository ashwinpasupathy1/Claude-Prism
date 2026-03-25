// ProjectState.swift — Codable snapshot of the navigator tree for JSON persistence.

import Foundation

struct ProjectState: Codable {

    struct TableState: Codable {
        let id: String
        var label: String
        let tableType: String
        var dataFilePath: String?
        var sheets: [SheetState]
    }

    struct SheetState: Codable {
        let id: String
        var label: String
        let kind: String
        var chartType: String?
        var notes: String?
    }

    var dataTables: [TableState]
    var activeDataTableID: String?
    var activeSheetID: String?

    // MARK: - Persistence path

    static var projectFileURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".refraction", isDirectory: true)
        return dir.appendingPathComponent("project.json")
    }

    /// Write pretty-printed JSON to ~/.refraction/project.json.
    func writeToDisk() {
        let dir = Self.projectFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: Self.projectFileURL, options: .atomic)
    }

    /// Read from ~/.refraction/project.json, if it exists.
    static func readFromDisk() -> ProjectState? {
        guard let data = try? Data(contentsOf: projectFileURL) else { return nil }
        return try? JSONDecoder().decode(ProjectState.self, from: data)
    }
}
