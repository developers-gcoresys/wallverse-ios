import XCTest
@testable import WallVerseCore

final class WallVerseCoreTests: XCTestCase {
    func testLoadsVerseLibraryAndRejectsEmptyInput() throws {
        let json = """
        [
          {"reference":"Psalm 23:1","text":"Yahweh is my shepherd; I shall lack nothing."},
          {"reference":"John 3:16","text":"For God so loved the world."}
        ]
        """.data(using: .utf8)!
        let verses = try VerseLibrary.load(data: json)
        XCTAssertEqual(verses.count, 2)
        XCTAssertEqual(verses[0].reference, "Psalm 23:1")
        XCTAssertFalse(VerseLibrary.fallback.isEmpty)

        XCTAssertThrowsError(try VerseLibrary.load(data: Data("[]".utf8))) { error in
            XCTAssertEqual(error as? VerseLibraryError, .empty)
        }
    }

    func testStylesMarkOnlyThreeAsPro() {
        XCTAssertEqual(WallpaperStyle.allCases.count, 5)
        XCTAssertEqual(WallpaperStyle.allCases.filter(\.isPro).map(\.rawValue), ["desertGold", "oceanCalm", "forest"])
    }

    func testAdPolicyRequiresTapsCooldownAndSessionCap() {
        var session = WallpaperAdSession(tapsPerAd: 4, cooldown: 120, maxAdsPerSession: 4)
        let start = Date(timeIntervalSince1970: 1_000_000)

        for _ in 0..<3 { XCTAssertFalse(session.recordNewVerse(at: start)) }
        XCTAssertTrue(session.recordNewVerse(at: start))
        session.markAdShown(at: start)
        XCTAssertEqual(session.adsShown, 1)

        for _ in 0..<4 { _ = session.recordNewVerse(at: start.addingTimeInterval(60)) }
        XCTAssertFalse(session.recordNewVerse(at: start.addingTimeInterval(60)))

        for _ in 0..<4 { _ = session.recordNewVerse(at: start.addingTimeInterval(121)) }
        XCTAssertTrue(session.recordNewVerse(at: start.addingTimeInterval(121)))
        session.markAdShown(at: start.addingTimeInterval(121))
        XCTAssertEqual(session.adsShown, 2)

        for _ in 0..<4 { _ = session.recordNewVerse(at: start.addingTimeInterval(1000)) }
        XCTAssertTrue(session.recordNewVerse(at: start.addingTimeInterval(1000)))
        session.markAdShown(at: start.addingTimeInterval(1000))
        XCTAssertEqual(session.adsShown, 3)

        for _ in 0..<4 { _ = session.recordNewVerse(at: start.addingTimeInterval(2000)) }
        XCTAssertTrue(session.recordNewVerse(at: start.addingTimeInterval(2000)))
        session.markAdShown(at: start.addingTimeInterval(2000))
        XCTAssertEqual(session.adsShown, 4)

        for _ in 0..<50 { XCTAssertFalse(session.recordNewVerse(at: start.addingTimeInterval(10_000))) }
    }

    func testEntitlementDecodesExpiryAndRejectsMissingExpiry() throws {
        let json = """
        {"appId":"wallverse","isPro":true,"status":"active","productId":"pro_monthly",
         "expiresAt":"2027-01-09T12:00:00.000Z","willRenew":true}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = WallpaperISO8601.date(from: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
            }
            return date
        }
        let entitlement = try decoder.decode(ProEntitlement.self, from: json)
        XCTAssertTrue(entitlement.isActivePro(at: Date(timeIntervalSince1970: 1_780_000_000)))
        XCTAssertFalse(entitlement.isActivePro(at: Date(timeIntervalSince1970: 1_900_000_000)))
        XCTAssertFalse(ProEntitlement.inactive.isActivePro())
    }
}
