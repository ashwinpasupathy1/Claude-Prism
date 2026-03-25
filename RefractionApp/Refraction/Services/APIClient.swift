// APIClient.swift — Async HTTP client for the Python analysis engine.
// Communicates with the FastAPI server on 127.0.0.1:7331.

import Foundation
import RefractionRenderer

actor APIClient {

    static let shared = APIClient()

    private let baseURL = "http://127.0.0.1:7331"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Send a render request and decode the ChartSpec response.
    func analyze(chartType: ChartType, config: ChartConfig) async throws -> ChartSpec {
        let body: [String: Any] = [
            "chart_type": chartType.key,
            "kw": config.toDict()
        ]

        let data = try await post(path: "/render", body: body)

        // Decode the envelope
        let response = try JSONDecoder().decode(RenderResponse.self, from: data)

        guard response.ok, let spec = response.spec else {
            throw APIError.serverError(response.error ?? "Unknown server error")
        }

        return spec
    }

    /// Send a render request and return both the decoded ChartSpec and pretty-printed raw JSON.
    func analyzeWithRawJSON(chartType: ChartType, config: ChartConfig) async throws -> (ChartSpec, String) {
        let body: [String: Any] = [
            "chart_type": chartType.key,
            "kw": config.toDict()
        ]

        let data = try await post(path: "/render", body: body)

        // Pretty-print the raw JSON
        let rawJSON: String
        if let jsonObj = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            rawJSON = prettyString
        } else {
            rawJSON = String(data: data, encoding: .utf8) ?? "(unable to decode)"
        }

        let response = try JSONDecoder().decode(RenderResponse.self, from: data)
        guard response.ok, let spec = response.spec else {
            throw APIError.serverError(response.error ?? "Unknown server error")
        }

        return (spec, rawJSON)
    }

    /// Check if the Python server is healthy.
    func health() async throws -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            return false
        }

        struct HealthResponse: Decodable {
            let status: String
        }

        let health = try JSONDecoder().decode(HealthResponse.self, from: data)
        return health.status == "ok"
    }

    /// Upload a file to the Python server and return the server-side path.
    func upload(fileURL: URL) async throws -> String {
        let url = URL(string: "\(baseURL)/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw APIError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        struct UploadResponse: Decodable {
            let ok: Bool
            let path: String?
            let error: String?
        }

        let uploadResp = try JSONDecoder().decode(UploadResponse.self, from: data)
        guard uploadResp.ok, let path = uploadResp.path else {
            throw APIError.serverError(uploadResp.error ?? "Upload failed")
        }

        return path
    }

    /// Fetch a read-only preview of the data in an Excel/CSV file.
    func dataPreview(excelPath: String, sheet: Int = 0) async throws -> DataPreviewResponse {
        let body: [String: Any] = [
            "excel_path": excelPath,
            "sheet": sheet
        ]
        let data = try await post(path: "/data-preview", body: body)
        return try JSONDecoder().decode(DataPreviewResponse.self, from: data)
    }

    /// Recommend the best statistical test for the data.
    func recommendTest(excelPath: String, paired: Bool = false) async throws -> RecommendTestResponse {
        let body: [String: Any] = [
            "excel_path": excelPath,
            "paired": paired,
        ]
        let data = try await post(path: "/recommend-test", body: body)
        return try JSONDecoder().decode(RecommendTestResponse.self, from: data)
    }

    /// Run a standalone statistical analysis and return comprehensive results.
    func analyzeStats(
        excelPath: String,
        analysisType: String,
        paired: Bool = false,
        posthoc: String = "Tukey HSD",
        mcCorrection: String = "Holm-Bonferroni",
        control: String? = nil
    ) async throws -> AnalyzeStatsResponse {
        var body: [String: Any] = [
            "excel_path": excelPath,
            "analysis_type": analysisType,
            "paired": paired,
            "posthoc": posthoc,
            "mc_correction": mcCorrection,
        ]
        if let control { body["control"] = control }
        let data = try await post(path: "/analyze-stats", body: body)
        let response = try JSONDecoder().decode(AnalyzeStatsResponse.self, from: data)

        // Attach the raw JSON for developer mode display
        if let jsonObj = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            response.rawJSON = prettyString
        }

        return response
    }

    /// Save the current project as a .refract file at the given path.
    func saveProject(outputPath: String, projectState: [String: Any]) async throws -> String {
        let body: [String: Any] = [
            "output_path": outputPath,
            "project": projectState
        ]
        let data = try await post(path: "/project/save-refract", body: body)

        struct SaveResponse: Decodable {
            let ok: Bool
            let path: String?
            let error: String?
        }

        let resp = try JSONDecoder().decode(SaveResponse.self, from: data)
        guard resp.ok, let path = resp.path else {
            throw APIError.serverError(resp.error ?? "Save failed")
        }
        return path
    }

    // MARK: - Private helpers

    private func post(path: String, body: [String: Any]) async throws -> Data {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard http.statusCode == 200 else {
            // Try to extract error message from response body
            if let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = errorObj["error"] as? String {
                throw APIError.serverError(errorMsg)
            }
            throw APIError.httpError(statusCode: http.statusCode)
        }

        return data
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case serverError(String)
    case httpError(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

// MARK: - Data Preview Response

struct DataPreviewResponse: Decodable {
    let ok: Bool
    let columns: [String]?
    let rows: [[AnyCellValue]]?
    let shape: [Int]?
    let error: String?
}

// MARK: - Recommend Test Response

struct RecommendTestResponse: Decodable {
    let ok: Bool
    let test: String?
    let testLabel: String?
    let posthoc: String?
    let justification: String?
    let error: String?
    let checks: DiagnosticChecks?

    enum CodingKeys: String, CodingKey {
        case ok, test, posthoc, justification, error, checks
        case testLabel = "test_label"
    }
}

/// Diagnostic checks returned by /recommend-test
struct DiagnosticChecks: Decodable {
    let nGroups: Int
    let paired: Bool
    let allNormal: Bool
    let equalVariance: Bool
    let leveneP: Double?
    let minN: Int
    let normality: [String: NormalityResult]

    enum CodingKeys: String, CodingKey {
        case paired, normality
        case nGroups = "n_groups"
        case allNormal = "all_normal"
        case equalVariance = "equal_variance"
        case leveneP = "levene_p"
        case minN = "min_n"
    }
}

struct NormalityResult: Decodable {
    let stat: Double?
    let p: Double?
    let normal: Bool
}

// MARK: - Analyze Stats Response

final class AnalyzeStatsResponse: Decodable {
    let ok: Bool
    let analysisType: String?
    let analysisLabel: String?
    let recommendation: RecommendationResult?
    let descriptive: [[String: AnyCellValue]]?
    let comparisons: [[String: AnyCellValue]]?
    let summary: String?
    let error: String?
    /// Raw JSON string from the API (set after decoding, not part of the JSON).
    var rawJSON: String = ""

    enum CodingKeys: String, CodingKey {
        case ok
        case analysisType = "analysis_type"
        case analysisLabel = "analysis_label"
        case recommendation, descriptive, comparisons, summary, error
    }
}

struct RecommendationResult: Decodable {
    let test: String
    let testLabel: String
    let posthoc: String?
    let justification: String

    enum CodingKeys: String, CodingKey {
        case test
        case testLabel = "test_label"
        case posthoc, justification
    }
}

enum AnyCellValue: Decodable {
    case string(String)
    case number(Double)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let d = try? container.decode(Double.self) {
            self = .number(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            self = .null
        }
    }

    var displayString: String {
        switch self {
        case .string(let s): return s
        case .number(let d):
            if d == d.rounded() && abs(d) < 1e15 {
                return String(format: "%.0f", d)
            }
            return String(format: "%.4g", d)
        case .null: return ""
        }
    }
}
