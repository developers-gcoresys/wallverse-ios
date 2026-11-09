import Foundation
import WallVerseCore

// Lightweight checks for environments with Command Line Tools only (no XCTest).
// Run with `swift run CoreChecks`. Xcode users can run `swift test` instead.

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

let verses = VerseLibrary.fallback
expect(!verses.isEmpty, "fallback verses should not be empty")
expect(verses[0].reference == "John 3:16", "fallback order")

let json = """
[
  {"reference":"Psalm 23:1","text":"Yahweh is my shepherd; I shall lack nothing."},
  {"reference":"John 3:16","text":"For God so loved the world."}
]
""".data(using: .utf8)!
let loaded = try VerseLibrary.load(data: json)
expect(loaded.count == 2, "loads bundled verse JSON")
expect(loaded[1].reference == "John 3:16", "keeps order")

do {
    _ = try VerseLibrary.load(data: Data("[]".utf8))
    expect(false, "empty library should throw")
} catch {
    expect(error as? VerseLibraryError == .empty, "empty library error")
}

expect(WallpaperStyle.softLight.isPro == false, "soft light is free")
expect(WallpaperStyle.midnight.isPro == false, "midnight is free")
expect(WallpaperStyle.desertGold.isPro, "desert gold is Pro")
expect(WallpaperStyle.oceanCalm.isPro, "ocean calm is Pro")
expect(WallpaperStyle.forest.isPro, "forest is Pro")
expect(WallpaperStyle.allCases.count == 5, "five styles")
expect(WallpaperStyle.softLight.backgroundHex == "F7F4ED", "background hex")

var session = WallpaperAdSession(tapsPerAd: 8, cooldown: 240, maxAdsPerSession: 2)
let start = Date(timeIntervalSince1970: 1_000_000)
for _ in 0..<7 { expect(!session.recordNewVerse(at: start), "ad not due before 8 taps") }
expect(session.recordNewVerse(at: start), "ad due at 8 taps")
session.markAdShown(at: start)
expect(session.adsShown == 1, "first ad recorded")

for _ in 0..<8 { _ = session.recordNewVerse(at: start.addingTimeInterval(60)) }
expect(!session.recordNewVerse(at: start.addingTimeInterval(60)), "cooldown blocks")
for _ in 0..<8 { _ = session.recordNewVerse(at: start.addingTimeInterval(241)) }
expect(session.recordNewVerse(at: start.addingTimeInterval(242)), "second ad after cooldown")
session.markAdShown(at: start.addingTimeInterval(242))
for _ in 0..<50 { expect(!session.recordNewVerse(at: start.addingTimeInterval(10_000)), "session cap") }

let entitlementJSON = """
{"appId":"wallverse","isPro":true,"status":"active","productId":"pro_monthly",
 "expiresAt":"2027-01-09T12:00:00.000Z","willRenew":true}
""".data(using: .utf8)!
let entitlement = try JSONDecoder.iso8601.decode(ProEntitlement.self, from: entitlementJSON)
expect(entitlement.isActivePro(at: Date(timeIntervalSince1970: 1_780_000_000)), "active before expiry")
expect(!entitlement.isActivePro(at: Date(timeIntervalSince1970: 1_900_000_000)), "expired after expiry")
expect(!ProEntitlement.inactive.isActivePro(), "inactive is not Pro")

print("WallVerseCore checks passed")

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = WallpaperISO8601.date(from: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date")
            }
            return date
        }
        return decoder
    }
}
