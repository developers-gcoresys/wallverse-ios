# WallVerse — iOS

The iOS companion to WallVerse Android: a verse wallpaper app with five styles,
AdMob ads for free users, and a server-verified **WallVerse Pro** subscription.
It shares the `gcoreapps-backend` Pro backend with the Android apps.

## Status

- SwiftUI wallpaper preview rendered locally at 1080×2400.
- Five styles: Soft light and Midnight free; Desert gold, Ocean calm, and Forest
  require Pro.
- **Save to Photos** and **Share** export the full-resolution image. iOS does not
  allow apps to set wallpaper directly, so the app explains the final manual
  step (Photos → Share → Use as Wallpaper).
- StoreKit 2 subscriptions (`pro_monthly`, `pro_yearly`) verified server-side
  through `verifyProPurchase` with `platform: "ios"`.
- Firebase Auth (Google and Sign in with Apple) and App Check.
- AdMob banner + interaction-triggered interstitial gated by UMP consent.
  Google test IDs are used until production iOS ad units exist.

## Layout

```
wallverse-ios/
├── project.yml                  # XcodeGen spec (source of truth)
├── WallVerse.xcodeproj          # generated; do not hand-edit
├── WallVerseCore/               # platform-neutral Swift package + checks
│   ├── Sources/WallVerseCore/   # models, styles, verse library, ads, Pro model
│   ├── Checks/                  # runnable checks without Xcode
│   └── Tests/                   # XCTest suite for Xcode
├── App/
│   ├── Sources/                 # SwiftUI app, renderer, Firebase, StoreKit, AdMob
│   ├── Resources/               # verses.json, assets, StoreKit config
│   ├── Info.plist
│   └── WallVerse.entitlements
└── tools/sync-content.sh
```

## Build

Requires Xcode 16+ and iOS 17+.

```sh
brew install xcodegen
xcodegen generate
open WallVerse.xcodeproj
```

Select the `WallVerse` scheme. The generated scheme already points at
`App/Resources/Configuration.storekit` for local StoreKit testing.

Without Xcode, the shared logic still builds:

```sh
cd WallVerseCore
swift run CoreChecks
```

With Xcode installed, `swift test` runs the XCTest suite.

### Signing

Set your team in Xcode (Signing & Capabilities) or set `DEVELOPMENT_TEAM` in
`project.yml`. The app declares **Sign in with Apple**. Without an Apple
Developer account the project compiles for the simulator, but Sign in with Apple
and App Attest will not work.

## Firebase setup

1. Register `com.gcoreapps.wallverse` in the shared Firebase project as an iOS app.
2. Add `GoogleService-Info.plist` to `App/Resources/` (gitignored).
3. Add its reversed client ID as a URL scheme in `App/Info.plist`, replacing
   `REPLACE_WITH_REVERSED_CLIENT_ID`.
4. The backend uses `FIREBASE_APP_ID_WALLVERSE` for both Android and iOS App
   Check registration.
5. Enable Google and Apple sign-in in Firebase Authentication.
6. Enable App Check: App Attest for release, debug provider for the simulator.

If `GoogleService-Info.plist` is missing, the app remains usable and Pro screens
show a configuration message.

## App Store subscriptions

Create a subscription group **Pro** with `pro_monthly` and `pro_yearly`. The
backend allow-lists those exact IDs for the `wallverse` app.

Purchases set `Product.PurchaseOption.appAccountToken` to a Keychain UUID. The
backend rejects subscriptions without a token and binds the purchase to the
signed-in Firebase account. The client never unlocks Pro from StoreKit alone.

## Ads and consent

Ad IDs live in `App/Info.plist` (`GADApplicationIdentifier`,
`AdMobBannerUnitID`, `AdMobInterstitialUnitID`). Replace the Google test IDs
before release.

`WallVerseCore/WallpaperAdSession` mirrors Android: an interstitial becomes
eligible after 8 **New verse** taps, with a 4-minute cooldown and at most 2 per
app session. Pro users see no banner and no interstitial. No ad is requested
before UMP consent is available.

## Content

`App/Resources/verses.json` is copied from WallVerse Android and uses
public-domain World English Bible verses. Sync it rather than editing both
copies:

```sh
tools/sync-content.sh ../wallverse-android/app/src/main/assets
```

Run `tools/check-content.sh` to fail if the iOS bundle drifts from the canonical
Android content. `swift run CoreChecks` also loads the bundled list and verifies
its size and first/last entries.

Do not add translations or editions until their rights and attribution are
reviewed.

## Verification before release

- [ ] `swift run CoreChecks` passes.
- [ ] `tools/check-content.sh` passes against the Android repo.
- [ ] `xcodebuild -scheme WallVerse -destination 'generic/platform=iOS Simulator' build` succeeds.
- [ ] Backend `npm test` passes.
- [ ] Sandbox purchase, renewal, cancel, refund, and restore produce the expected
      server entitlement.
- [ ] App Check is enforced for the iOS app.
- [ ] UMP consent appears on a fresh install and no ad is requested before it.
- [ ] Production AdMob and App Store product IDs replace all placeholders.
- [ ] Save-to-Photos and Share export a readable 1080×2400 image.
- [ ] Privacy labels and the App Store listing are complete.
