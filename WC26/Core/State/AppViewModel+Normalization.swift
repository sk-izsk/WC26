import Foundation

extension AppViewModel {
    func normalizeMatch(_ apiGame: APIGame) -> Match {
        let homeTeamRecord = teamsByID[apiGame.homeTeamID]
        let awayTeamRecord = teamsByID[apiGame.awayTeamID]
        let stadium = stadiumsByID[apiGame.stadiumID]
        let matchStatus = api.apiStatus(for: apiGame)
        let kickoffDate = parseKickoffDate(for: apiGame, stadium: stadium)
        let liveClock = parseLiveClock(apiGame.timeElapsed, status: matchStatus)
        let minute = parseMinute(apiGame.timeElapsed, status: matchStatus)

        let homeName = resolvedTeamName(
            explicitName: apiGame.homeTeamNameEn,
            team: homeTeamRecord,
            placeholder: apiGame.homeTeamLabel
        )
        let awayName = resolvedTeamName(
            explicitName: apiGame.awayTeamNameEn,
            team: awayTeamRecord,
            placeholder: apiGame.awayTeamLabel
        )

        let homeMenuLabel = menuLabel(for: homeTeamRecord, fallbackName: homeName)
        let awayMenuLabel = menuLabel(for: awayTeamRecord, fallbackName: awayName)

        let kickoffLabel = kickoffDate.map(Date.matchTimeString) ?? apiGame.localDate

        return Match(
            id: apiGame.id,
            matchNumber: Int(apiGame.id) ?? 0,
            round: apiGame.type.uppercased(),
            groupName: apiGame.group,
            homeTeamID: apiGame.homeTeamID,
            awayTeamID: apiGame.awayTeamID,
            homeTeam: homeName,
            awayTeam: awayName,
            homeMenuLabel: homeMenuLabel,
            awayMenuLabel: awayMenuLabel,
            homeFlagEmoji: homeTeamRecord?.iso2.flagEmoji ?? "",
            awayFlagEmoji: awayTeamRecord?.iso2.flagEmoji ?? "",
            homeFlagURL: homeTeamRecord.flatMap { URL(string: $0.flag) },
            awayFlagURL: awayTeamRecord.flatMap { URL(string: $0.flag) },
            stadium: stadium?.nameEn ?? "Venue TBD",
            city: stadium?.cityEn ?? "",
            kickoffDate: kickoffDate,
            kickoffLabel: kickoffLabel,
            status: matchStatus,
            homeScore: parsedScore(apiGame.homeScore, status: matchStatus),
            awayScore: parsedScore(apiGame.awayScore, status: matchStatus),
            liveClock: liveClock,
            minute: minute,
            homeScorers: scorerList(from: apiGame.homeScorers),
            awayScorers: scorerList(from: apiGame.awayScorers)
        )
    }

    func menuLabel(for team: APITeam?, fallbackName: String) -> String {
        if let code = team?.fifaCode.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty {
            return code.uppercased()
        }

        let words = fallbackName
            .split(whereSeparator: \.isWhitespace)
            .prefix(3)
            .map(String.init)

        if words.count >= 2 {
            let initials = words.compactMap { $0.first }.map { String($0).uppercased() }.joined()
            if !initials.isEmpty {
                return initials
            }
        }

        return String(fallbackName.prefix(3)).uppercased()
    }

    func normalizeStanding(_ apiGroup: APIGroup) -> GroupStanding {
        let sortedRows = apiGroup.teams
            .map { team in
                let teamRecord = teamsByID[team.teamID]
                let played = Int(team.played) ?? 0
                let won = Int(team.won) ?? 0
                let drawn = Int(team.drawn) ?? 0
                let lost = Int(team.lost) ?? 0
                let goalsFor = Int(team.goalsFor) ?? 0
                let goalsAgainst = Int(team.goalsAgainst) ?? 0
                let goalDifference = Int(team.goalDifference) ?? 0
                let points = Int(team.points) ?? 0

                return (
                    teamID: team.teamID,
                    teamName: teamRecord?.nameEn ?? "TBD",
                    flagURL: teamRecord.flatMap { URL(string: $0.flag) },
                    played: played,
                    won: won,
                    drawn: drawn,
                    lost: lost,
                    goalsFor: goalsFor,
                    goalsAgainst: goalsAgainst,
                    goalDifference: goalDifference,
                    points: points
                )
            }
            .sorted { lhs, rhs in
                if lhs.points != rhs.points {
                    return lhs.points > rhs.points
                }
                if lhs.goalDifference != rhs.goalDifference {
                    return lhs.goalDifference > rhs.goalDifference
                }
                if lhs.goalsFor != rhs.goalsFor {
                    return lhs.goalsFor > rhs.goalsFor
                }
                if lhs.won != rhs.won {
                    return lhs.won > rhs.won
                }
                return lhs.teamName < rhs.teamName
            }

        let rows = sortedRows.enumerated().map { index, team in
            let teamRecord = teamsByID[team.teamID]
            return StandingRow(
                teamID: team.teamID,
                position: index + 1,
                team: teamRecord?.nameEn ?? team.teamName,
                flagURL: team.flagURL,
                played: team.played,
                won: team.won,
                drawn: team.drawn,
                lost: team.lost,
                goalsFor: team.goalsFor,
                goalsAgainst: team.goalsAgainst,
                goalDifference: team.goalDifference,
                points: team.points
            )
        }

        return GroupStanding(group: apiGroup.group, standings: rows)
    }

    func parseKickoffDate(for apiGame: APIGame, stadium: APIStadium?) -> Date? {
        let venueTimeZone = stadium.flatMap(timeZone(for:)) ?? TimeZone.current
        return Date.parseMatchDate(apiGame.localDate, in: venueTimeZone)
    }

    func parsedScore(_ rawValue: String, status: MatchStatus) -> Int? {
        guard status != .scheduled else {
            return nil
        }
        return Int(rawValue)
    }

    func parseMinute(_ rawValue: String, status: MatchStatus) -> Int? {
        guard status == .inPlay else {
            return nil
        }

        let digits = rawValue.filter(\.isNumber)
        return Int(digits)
    }

    func parseLiveClock(_ rawValue: String, status: MatchStatus) -> String? {
        guard status == .inPlay else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let regex = try? NSRegularExpression(pattern: "(\\d+)(?:\\D*\\+\\D*(\\d+))?"),
           let match = regex.firstMatch(
               in: trimmed,
               range: NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
           ),
           let baseRange = Range(match.range(at: 1), in: trimmed) {
            let base = String(trimmed[baseRange])
            if let extraRange = Range(match.range(at: 2), in: trimmed) {
                let extra = String(trimmed[extraRange])
                return "\(base)'+\(extra)'"
            }
            return "\(base)'"
        }

        return nil
    }

    func resolvedTeamName(explicitName: String?, team: APITeam?, placeholder: String?) -> String {
        if let explicitName, !explicitName.isEmpty {
            return explicitName
        }
        if let team {
            return team.nameEn
        }
        if let placeholder, !placeholder.isEmpty {
            return placeholder
        }
        return "TBD"
    }

    func scorerList(from rawValue: String) -> [String] {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "null" else {
            return []
        }

        if let regex = try? NSRegularExpression(pattern: "\"([^\"]+)\"") {
            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            let matches = regex.matches(in: trimmed, range: range).compactMap { match -> String? in
                guard let scorerRange = Range(match.range(at: 1), in: trimmed) else {
                    return nil
                }
                return String(trimmed[scorerRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if !matches.isEmpty {
                return matches
            }
        }

        let sanitized = trimmed
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")

        return sanitized
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != "null" }
    }

    func timeZone(for stadium: APIStadium) -> TimeZone? {
        switch stadium.id {
        case "1", "2":
            return TimeZone(identifier: "America/Mexico_City")
        case "3":
            return TimeZone(identifier: "America/Monterrey")
        case "4", "5", "6":
            return TimeZone(identifier: "America/Chicago")
        case "7", "8", "9", "10", "11":
            return TimeZone(identifier: "America/New_York")
        case "12":
            return TimeZone(identifier: "America/Toronto")
        case "13":
            return TimeZone(identifier: "America/Vancouver")
        case "14", "15", "16":
            return TimeZone(identifier: "America/Los_Angeles")
        default:
            return fallbackTimeZone(city: stadium.cityEn, country: stadium.countryEn)
        }
    }

    func fallbackTimeZone(city: String, country: String) -> TimeZone? {
        let normalized = city.lowercased()
        if country == "Canada" {
            if normalized.contains("toronto") { return TimeZone(identifier: "America/Toronto") }
            if normalized.contains("vancouver") { return TimeZone(identifier: "America/Vancouver") }
        }
        if country == "Mexico" {
            if normalized.contains("monterrey") { return TimeZone(identifier: "America/Monterrey") }
            return TimeZone(identifier: "America/Mexico_City")
        }
        if normalized.contains("los angeles") || normalized.contains("inglewood") || normalized.contains("santa clara") || normalized.contains("san francisco") || normalized.contains("seattle") {
            return TimeZone(identifier: "America/Los_Angeles")
        }
        if normalized.contains("dallas") || normalized.contains("arlington") || normalized.contains("houston") || normalized.contains("kansas city") {
            return TimeZone(identifier: "America/Chicago")
        }
        return TimeZone(identifier: "America/New_York")
    }
}
