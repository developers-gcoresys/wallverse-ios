import Foundation

public struct WallpaperVerse: Codable, Hashable, Identifiable, Sendable {
    public let reference: String
    public let text: String

    public var id: String { "\(reference)|\(text)" }

    public init(reference: String, text: String) {
        self.reference = reference
        self.text = text
    }
}

public enum WallpaperStyle: String, CaseIterable, Identifiable, Sendable {
    case softLight
    case midnight
    case desertGold
    case oceanCalm
    case forest

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .softLight: return "Soft light"
        case .midnight: return "Midnight"
        case .desertGold: return "Desert gold"
        case .oceanCalm: return "Ocean calm"
        case .forest: return "Forest"
        }
    }

    public var isPro: Bool {
        switch self {
        case .softLight, .midnight: return false
        case .desertGold, .oceanCalm, .forest: return true
        }
    }

    /// sRGB hex values used by the renderer and by the UI preview.
    public var backgroundHex: String {
        switch self {
        case .softLight: return "F7F4ED"
        case .midnight: return "101820"
        case .desertGold: return "3B2E1E"
        case .oceanCalm: return "0F2A33"
        case .forest: return "1E2A1D"
        }
    }

    public var foregroundHex: String {
        switch self {
        case .softLight: return "26352E"
        case .midnight: return "F4F1E8"
        case .desertGold: return "F5D9A6"
        case .oceanCalm: return "CFE8E4"
        case .forest: return "D7E8C6"
        }
    }
}

public enum VerseLibraryError: Error, Equatable {
    case empty
    case malformed
}

public enum VerseLibrary {
    public static let fallback: [WallpaperVerse] = [
        WallpaperVerse(reference: "John 3:16", text: "For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life."),
        WallpaperVerse(reference: "Psalm 23:1", text: "Yahweh is my shepherd; I shall lack nothing."),
        WallpaperVerse(reference: "Philippians 4:13", text: "I can do all things through Christ, who strengthens me."),
        WallpaperVerse(reference: "Psalm 46:10", text: "Be still, and know that I am God."),
        WallpaperVerse(reference: "Psalm 119:105", text: "Your word is a lamp to my feet, and a light for my path.")
    ]

    public static func load(data: Data) throws -> [WallpaperVerse] {
        guard let verses = try? JSONDecoder().decode([WallpaperVerse].self, from: data) else {
            throw VerseLibraryError.malformed
        }
        guard !verses.isEmpty else { throw VerseLibraryError.empty }
        return verses
    }
}

/// Interaction-triggered interstitial policy for WallVerse. Free users get an
/// ad after repeated "New verse" taps, subject to a cooldown and session cap.
public struct WallpaperAdSession: Sendable, Equatable {
    public let tapsPerAd: Int
    public let cooldown: TimeInterval
    public let maxAdsPerSession: Int

    public private(set) var tapsSinceAd: Int
    public private(set) var adsShown: Int
    public private(set) var lastAdAt: Date?

    public init(tapsPerAd: Int = 4, cooldown: TimeInterval = 120, maxAdsPerSession: Int = 4) {
        self.tapsPerAd = tapsPerAd
        self.cooldown = cooldown
        self.maxAdsPerSession = maxAdsPerSession
        self.tapsSinceAd = 0
        self.adsShown = 0
        self.lastAdAt = nil
    }

    public mutating func recordNewVerse(at date: Date) -> Bool {
        guard adsShown < maxAdsPerSession else { return false }
        tapsSinceAd += 1
        guard tapsSinceAd >= tapsPerAd else { return false }
        if let lastAdAt, date.timeIntervalSince(lastAdAt) < cooldown { return false }
        return true
    }

    public mutating func markAdShown(at date: Date) {
        adsShown += 1
        tapsSinceAd = 0
        lastAdAt = date
    }
}

public enum WallpaperProductIDs {
    public static let monthly = "pro_monthly"
    public static let yearly = "pro_yearly"
    public static let all = [monthly, yearly]
}

public enum WallpaperISO8601 {
    private static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public static func date(from string: String) -> Date? {
        fractional.date(from: string) ?? plain.date(from: string)
    }
}

public struct ProEntitlement: Codable, Equatable, Sendable {
    public let appId: String
    public let isPro: Bool
    public let status: String
    public let productId: String?
    public let expiresAt: Date?
    public let willRenew: Bool

    public init(appId: String, isPro: Bool, status: String, productId: String?, expiresAt: Date?, willRenew: Bool) {
        self.appId = appId
        self.isPro = isPro
        self.status = status
        self.productId = productId
        self.expiresAt = expiresAt
        self.willRenew = willRenew
    }

    public static let inactive = ProEntitlement(appId: "", isPro: false, status: "inactive", productId: nil, expiresAt: nil, willRenew: false)

    public func isActivePro(at date: Date = Date()) -> Bool {
        guard isPro, let expiresAt else { return false }
        return expiresAt > date
    }
}
