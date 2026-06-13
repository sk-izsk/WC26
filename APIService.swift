import Foundation

final class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    private var baseURL: String {
        Bundle.main.infoDictionary?["WC_API_BASE_URL"] as? String ?? "https://worldcup26.ir"
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    func fetchMatches() async throws -> [APIGame] {
        let request = try makeRequest(path: "/get/games")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(APIGamesResponse.self, from: data).games
    }

    func fetchGroups() async throws -> [APIGroup] {
        let request = try makeRequest(path: "/get/groups")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(APIGroupsResponse.self, from: data).groups
    }

    func fetchTeams() async throws -> [APITeam] {
        let request = try makeRequest(path: "/get/teams")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(APITeamsResponse.self, from: data).teams
    }

    func fetchStadiums() async throws -> [APIStadium] {
        let request = try makeRequest(path: "/get/stadiums")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(APIStadiumsResponse.self, from: data).stadiums
    }

    func fetchLiveMatches() async throws -> [APIGame] {
        let matches = try await fetchMatches()
        return matches.filter { apiStatus(for: $0).isLive }
    }

    func apiStatus(for game: APIGame) -> MatchStatus {
        if game.finished.uppercased() == "TRUE" {
            return .finished
        }

        let elapsed = game.timeElapsed.lowercased()
        if elapsed.contains("half") {
            return .halfTime
        }
        if elapsed != "notstarted", elapsed != "ns", !elapsed.isEmpty {
            return .inPlay
        }
        return .scheduled
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            return
        }

        switch http.statusCode {
        case 200 ... 299:
            return
        case 401, 403:
            throw AppError.unauthorized
        case 429:
            throw AppError.rateLimited
        default:
            throw AppError.serverError(http.statusCode)
        }
    }
}

enum AppError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .unauthorized:
            return "API rejected the request."
        case .rateLimited:
            return "Rate limited. Retrying soon."
        case .serverError(let code):
            return "Server error \(code)."
        }
    }
}
