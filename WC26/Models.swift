import Foundation

enum MatchStatus: String, Codable {
    case scheduled
    case inPlay = "in_play"
    case halfTime = "half_time"
    case finished

    var isLive: Bool {
        self == .inPlay || self == .halfTime
    }
}

struct APIGamesResponse: Decodable {
    let games: [APIGame]

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            games = try keyed.decodeIfPresent([APIGame].self, forKey: .games) ?? []
            return
        }

        let container = try decoder.singleValueContainer()
        games = try container.decode([APIGame].self)
    }

    private enum CodingKeys: String, CodingKey {
        case games
    }
}

struct APIGroupsResponse: Decodable {
    let groups: [APIGroup]

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            groups = try keyed.decodeIfPresent([APIGroup].self, forKey: .groups) ?? []
            return
        }

        let container = try decoder.singleValueContainer()
        groups = try container.decode([APIGroup].self)
    }

    private enum CodingKeys: String, CodingKey {
        case groups
    }
}

struct APITeamsResponse: Decodable {
    let teams: [APITeam]

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            teams = try keyed.decodeIfPresent([APITeam].self, forKey: .teams) ?? []
            return
        }

        let container = try decoder.singleValueContainer()
        teams = try container.decode([APITeam].self)
    }

    private enum CodingKeys: String, CodingKey {
        case teams
    }
}

struct APIStadiumsResponse: Decodable {
    let stadiums: [APIStadium]

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            stadiums = try keyed.decodeIfPresent([APIStadium].self, forKey: .stadiums) ?? []
            return
        }

        let container = try decoder.singleValueContainer()
        stadiums = try container.decode([APIStadium].self)
    }

    private enum CodingKeys: String, CodingKey {
        case stadiums
    }
}

struct APIGame: Decodable, Identifiable {
    let mongoID: String?
    let id: String
    let homeTeamID: String
    let awayTeamID: String
    let homeScore: String
    let awayScore: String
    let homeScorers: String
    let awayScorers: String
    let group: String
    let matchday: String
    let localDate: String
    let stadiumID: String
    let finished: String
    let timeElapsed: String
    let type: String
    let homeTeamNameEn: String?
    let awayTeamNameEn: String?
    let homeTeamLabel: String?
    let awayTeamLabel: String?

    enum CodingKeys: String, CodingKey {
        case mongoID = "_id"
        case id
        case homeTeamID = "home_team_id"
        case awayTeamID = "away_team_id"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case homeScorers = "home_scorers"
        case awayScorers = "away_scorers"
        case group
        case matchday
        case localDate = "local_date"
        case stadiumID = "stadium_id"
        case finished
        case timeElapsed = "time_elapsed"
        case type
        case homeTeamNameEn = "home_team_name_en"
        case awayTeamNameEn = "away_team_name_en"
        case homeTeamLabel = "home_team_label"
        case awayTeamLabel = "away_team_label"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mongoID = try container.decodeIfPresent(String.self, forKey: .mongoID)
        id = container.decodeLossyString(forKey: .id) ?? UUID().uuidString
        homeTeamID = container.decodeLossyString(forKey: .homeTeamID) ?? "0"
        awayTeamID = container.decodeLossyString(forKey: .awayTeamID) ?? "0"
        homeScore = container.decodeLossyString(forKey: .homeScore) ?? "0"
        awayScore = container.decodeLossyString(forKey: .awayScore) ?? "0"
        homeScorers = container.decodeLossyString(forKey: .homeScorers) ?? "null"
        awayScorers = container.decodeLossyString(forKey: .awayScorers) ?? "null"
        group = container.decodeLossyString(forKey: .group) ?? ""
        matchday = container.decodeLossyString(forKey: .matchday) ?? ""
        localDate = container.decodeLossyString(forKey: .localDate) ?? ""
        stadiumID = container.decodeLossyString(forKey: .stadiumID) ?? "0"
        finished = container.decodeLossyString(forKey: .finished) ?? "FALSE"
        timeElapsed = container.decodeLossyString(forKey: .timeElapsed) ?? "notstarted"
        type = container.decodeLossyString(forKey: .type) ?? "group"
        homeTeamNameEn = container.decodeLossyString(forKey: .homeTeamNameEn)
        awayTeamNameEn = container.decodeLossyString(forKey: .awayTeamNameEn)
        homeTeamLabel = container.decodeLossyString(forKey: .homeTeamLabel)
        awayTeamLabel = container.decodeLossyString(forKey: .awayTeamLabel)
    }
}

struct APITeam: Decodable, Identifiable {
    let id: String
    let nameEn: String
    let flag: String
    let fifaCode: String
    let iso2: String
    let groups: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case flag
        case fifaCode = "fifa_code"
        case iso2
        case groups
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeLossyString(forKey: .id) ?? UUID().uuidString
        nameEn = container.decodeLossyString(forKey: .nameEn) ?? "TBD"
        flag = container.decodeLossyString(forKey: .flag) ?? ""
        fifaCode = container.decodeLossyString(forKey: .fifaCode) ?? ""
        iso2 = container.decodeLossyString(forKey: .iso2) ?? ""
        groups = container.decodeLossyString(forKey: .groups) ?? ""
    }
}

struct APIStadium: Decodable, Identifiable {
    let id: String
    let nameEn: String
    let cityEn: String
    let countryEn: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case cityEn = "city_en"
        case countryEn = "country_en"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeLossyString(forKey: .id) ?? UUID().uuidString
        nameEn = container.decodeLossyString(forKey: .nameEn) ?? "Venue TBD"
        cityEn = container.decodeLossyString(forKey: .cityEn) ?? ""
        countryEn = container.decodeLossyString(forKey: .countryEn) ?? ""
    }
}

struct APIGroup: Decodable, Identifiable {
    var id: String { group }
    let group: String
    let teams: [APIStandingTeam]

    enum CodingKeys: String, CodingKey {
        case group
        case name
        case teams
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        group = container.decodeLossyString(forKey: .group)
            ?? container.decodeLossyString(forKey: .name)
            ?? ""
        teams = try container.decodeIfPresent([APIStandingTeam].self, forKey: .teams) ?? []
    }
}

struct APIStandingTeam: Decodable {
    let teamID: String
    let played: String
    let won: String
    let lost: String
    let drawn: String
    let points: String
    let goalsFor: String
    let goalsAgainst: String
    let goalDifference: String

    enum CodingKeys: String, CodingKey {
        case teamID = "team_id"
        case played = "mp"
        case won = "w"
        case lost = "l"
        case drawn = "d"
        case points = "pts"
        case goalsFor = "gf"
        case goalsAgainst = "ga"
        case goalDifference = "gd"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        teamID = container.decodeLossyString(forKey: .teamID) ?? "0"
        played = container.decodeLossyString(forKey: .played) ?? "0"
        won = container.decodeLossyString(forKey: .won) ?? "0"
        lost = container.decodeLossyString(forKey: .lost) ?? "0"
        drawn = container.decodeLossyString(forKey: .drawn) ?? "0"
        points = container.decodeLossyString(forKey: .points) ?? "0"
        goalsFor = container.decodeLossyString(forKey: .goalsFor) ?? "0"
        goalsAgainst = container.decodeLossyString(forKey: .goalsAgainst) ?? "0"
        goalDifference = container.decodeLossyString(forKey: .goalDifference) ?? "0"
    }
}

struct Match: Identifiable, Equatable {
    let id: String
    let matchNumber: Int
    let round: String
    let groupName: String
    let homeTeamID: String
    let awayTeamID: String
    let homeTeam: String
    let awayTeam: String
    let homeMenuLabel: String
    let awayMenuLabel: String
    let homeFlagEmoji: String
    let awayFlagEmoji: String
    let homeFlagURL: URL?
    let awayFlagURL: URL?
    let stadium: String
    let city: String
    let kickoffDate: Date?
    let kickoffLabel: String
    let status: MatchStatus
    let homeScore: Int?
    let awayScore: Int?
    let minute: Int?
    let homeScorers: [String]
    let awayScorers: [String]

    var localDateKey: String {
        kickoffDate?.toDateKey() ?? Date().toDateKey()
    }

    var trayScoreline: String {
        let home = homeScore.map(String.init) ?? "-"
        let away = awayScore.map(String.init) ?? "-"
        return "\(homeMenuLabel) \(home)-\(away) \(awayMenuLabel)"
    }

    var trayMenuBarTitle: String {
        let home = homeScore.map(String.init) ?? "-"
        let away = awayScore.map(String.init) ?? "-"
        let leftFlag = homeFlagEmoji.isEmpty ? "" : "\(homeFlagEmoji) "
        let rightFlag = awayFlagEmoji.isEmpty ? "" : " \(awayFlagEmoji)"
        return "\(leftFlag)\(home)-\(away)\(rightFlag)"
    }

    var displayHomeScore: String {
        guard status != .scheduled else { return "-" }
        return homeScore.map(String.init) ?? "-"
    }

    var displayAwayScore: String {
        guard status != .scheduled else { return "-" }
        return awayScore.map(String.init) ?? "-"
    }

    var hasScorerData: Bool {
        !homeScorers.isEmpty || !awayScorers.isEmpty
    }

    func involvesFavoriteTeam(_ favoriteTeamIDs: Set<String>) -> Bool {
        favoriteTeamIDs.contains(homeTeamID) || favoriteTeamIDs.contains(awayTeamID)
    }
}

struct StandingRow: Identifiable, Equatable {
    let teamID: String
    let position: Int
    let team: String
    let flagURL: URL?
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int
    let points: Int

    var id: String { team }
}

struct GroupStanding: Identifiable, Equatable {
    let group: String
    let standings: [StandingRow]

    var id: String { group }
}

private extension KeyedDecodingContainer {
    func decodeLossyString(forKey key: Key) -> String? {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }
        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return String(doubleValue)
        }
        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolValue ? "true" : "false"
        }
        return nil
    }
}
