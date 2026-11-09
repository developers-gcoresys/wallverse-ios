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
- [ ] Add App Store Server Notifications V2 to the backend so renewals/refunds
      update without an app launch.
- [ ] Replace Google test AdMob IDs with production iOS app/banner/interstitial
      IDs and configure the UMP privacy message.
- [ ] Run a full sandbox purchase/restore/cancel/refund pass.
- [ ] Add app icons, screenshots, privacy labels, and the App Store listing.
- [ ] Build on a machine with Xcode; the current scaffold was generated and
      syntax-checked without Xcode.

## Next features

- [ ] WidgetKit daily verse widget.
- [ ] Daily verse notification with a configurable time.
- [ ] Verse favorites and a recents list, synced locally.
- [ ] More text layouts (top-aligned, large single-line) and font choices.
- [ ] Share-card export with a small WallVerse mark.
- [ ] Dynamic Type and VoiceOver audit.

## Policy

- [ ] Keep the manual "Use as Wallpaper" instruction visible; never imply the app
      sets wallpaper itself.
- [ ] Keep free-tier interstitials interaction-triggered only; no ads on launch.
- [ ] Keep Pro entitlements server-verified and app-scoped.
