import Foundation
import SwiftUI

private enum WCFormatters {
    static let dateKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let friendlyDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    static let dateStrip: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "EEE d"
        return formatter
    }()

    static let kickoffTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let kickoffFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "EEE, MMM d · HH:mm"
        return formatter
    }()
}

extension Color {
    static let bgBase = Color(red: 17 / 255, green: 17 / 255, blue: 20 / 255)
    static let bgCard = Color(red: 28 / 255, green: 28 / 255, blue: 32 / 255)
    static let bgCardLive = Color(red: 30 / 255, green: 20 / 255, blue: 20 / 255)
    static let bgHover = Color(red: 38 / 255, green: 38 / 255, blue: 44 / 255)
    static let borderColor = Color(red: 42 / 255, green: 42 / 255, blue: 48 / 255)
    static let accentLive = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
    static let accentQualified = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    static let accentPlayoff = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    static let textPrimary = Color(red: 246 / 255, green: 246 / 255, blue: 248 / 255)
    static let textSecondary = Color(red: 176 / 255, green: 176 / 255, blue: 188 / 255)
    static let textTime = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)
    static let liquidHighlight = Color(red: 120 / 255, green: 180 / 255, blue: 255 / 255)
    static let liquidGlow = Color(red: 68 / 255, green: 130 / 255, blue: 255 / 255)
    static let glassStroke = Color.white.opacity(0.18)
    static let glassTop = Color.white.opacity(0.18)
    static let glassBottom = Color.black.opacity(0.24)
}

extension Date {
    func toDateKey() -> String {
        WCFormatters.dateKey.string(from: self)
    }

    static func fromDateKey(_ key: String) -> Date? {
        WCFormatters.dateKey.date(from: key)
    }

    static func dateKey(offsetDays: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offsetDays, to: Date()) ?? Date()
        return date.toDateKey()
    }

    func friendlyDisplay() -> String {
        WCFormatters.friendlyDate.string(from: self)
    }

    func dateStripPillLabel() -> String {
        WCFormatters.dateStrip.string(from: self)
    }

    static func matchTimeString(_ date: Date) -> String {
        WCFormatters.kickoffTime.string(from: date)
    }

    static func matchFullKickoffString(_ date: Date) -> String {
        WCFormatters.kickoffFull.string(from: date)
    }

    static func parseMatchDate(_ rawValue: String, in timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "MM/dd/yyyy HH:mm"
        return formatter.date(from: rawValue)
    }
}

extension String {
    func toLocalTime() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]

        let output = DateFormatter()
        output.locale = Locale(identifier: "en_US_POSIX")
        output.timeZone = .current
        output.dateFormat = "HH:mm"

        if let date = formatter.date(from: self) ?? fallback.date(from: self) {
            return output.string(from: date)
        }

        return self
    }

    var flagEmoji: String {
        let uppercased = trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard uppercased.count == 2 else {
            return ""
        }

        let scalars = uppercased.unicodeScalars.compactMap { scalar -> UnicodeScalar? in
            guard scalar.value >= 65, scalar.value <= 90 else {
                return nil
            }
            return UnicodeScalar(127397 + Int(scalar.value))
        }

        guard scalars.count == 2 else {
            return ""
        }

        return String(String.UnicodeScalarView(scalars))
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 18, opacity: Double) -> some View {
        self
            .background(
                ZStack {
                    Color.black.opacity(0.22 + (opacity * 0.28))
                    LinearGradient(
                        colors: [Color.glassTop.opacity(opacity), Color.glassBottom.opacity(opacity * 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                        .opacity(opacity * 0.7)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.glassStroke.opacity(opacity + 0.1), lineWidth: 1)
            )
    }
}
