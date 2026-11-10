# TODO — WallVerse iOS

## Launch blockers

- [ ] Create the Apple Developer account, app record, and bundle ID
      `com.gcoreapps.wallverse`.
- [ ] Add signing team and enable the Sign in with Apple + App Attest capabilities.
- [ ] Register the iOS app in Firebase; add `GoogleService-Info.plist` and the
      reversed-client-ID URL scheme.
- [ ] Create `pro_monthly` and `pro_yearly` subscriptions in App Store Connect.
- [ ] Create the App Store Server API key and set `APP_STORE_ISSUER_ID`,
      `APP_STORE_KEY_ID`, and `APP_STORE_PRIVATE_KEY` in `gcoreapps-backend`.
- [x] Backend endpoint for App Store Server Notifications V2.
- [ ] Register the notification URL (with `APP_STORE_NOTIFICATION_TOKEN`) in
      App Store Connect so renewals/refunds update without an app launch.
- [ ] Replace Google test AdMob IDs with production iOS app/banner/interstitial
      IDs and configure the UMP privacy message.
- [ ] Run a full sandbox purchase/restore/cancel/refund pass.
- [ ] Add app icons, screenshots, privacy labels, and the App Store listing.
- [ ] Build on a machine with Xcode; the current scaffold was generated and
      syntax-checked without Xcode.

## Next features

- [x] WidgetKit daily verse widget.
- [x] Daily verse notification at 8:00 (30-day rolling window).
- [ ] Configurable notification time.
- [x] Privacy manifest (`App/Resources/PrivacyInfo.xcprivacy`).
- [ ] Verse favorites and a recents list, synced locally.
- [ ] More text layouts (top-aligned, large single-line) and font choices.
- [ ] Share-card export with a small WallVerse mark.
- [ ] Dynamic Type and VoiceOver audit.

## Policy

- [ ] Keep the manual "Use as Wallpaper" instruction visible; never imply the app
      sets wallpaper itself.
- [ ] Keep free-tier interstitials interaction-triggered only; no ads on launch.
- [ ] Keep Pro entitlements server-verified and app-scoped.
