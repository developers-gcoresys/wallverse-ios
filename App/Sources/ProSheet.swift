import SwiftUI
import AuthenticationServices
import CryptoKit
import Security
import WallVerseCore

enum AppleSignInNonce {
    static func random(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

struct ProSheet: View {
    @EnvironmentObject private var model: WallpaperModel
    @EnvironmentObject private var pro: ProManager
    @EnvironmentObject private var ads: AdsManager
    @Environment(\.dismiss) private var dismiss
    @State private var appleNonce = ""
    @State private var showingDeleteAccount = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                privacySection
                aboutSection
            }
            .navigationTitle("WallVerse Pro")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete account?", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) {}
                Button("Delete account", role: .destructive) {
                    Task { await pro.deleteAccount { model.clearLocalData() } }
                }
            } message: {
                Text(
                    "This permanently deletes your sign-in, Pro entitlement, and WallVerse account data. "
                        + "Your App Store subscription is not canceled — cancel it in the App Store if you do not want to be billed again."
                )
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            if !pro.configured {
                Text("Add GoogleService-Info.plist to enable sign-in, purchases, and server-verified Pro.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let email = pro.signedInEmail {
                LabeledContent("Signed in", value: email)
                Button("Sign out", role: .destructive) { pro.signOut() }
                Button("Delete account…", role: .destructive) { showingDeleteAccount = true }
                    .disabled(pro.busy)
            } else {
                Button {
                    Task { await pro.signInWithGoogle() }
                } label: {
                    Label("Continue with Google", systemImage: "person.crop.circle")
                }
                .disabled(!pro.configured || pro.busy)

                SignInWithAppleButton(.signIn) { request in
                    let nonce = AppleSignInNonce.random()
                    appleNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleSignInNonce.sha256(nonce)
                } onCompletion: { result in
                    Task { await pro.completeAppleSignIn(result, rawNonce: appleNonce) }
                }
                .frame(height: 44)
                .disabled(!pro.configured || pro.busy)
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Text("Status")
                Spacer()
                Text(pro.isPro ? "Pro" : "Free")
                    .foregroundStyle(pro.isPro ? WallVersePalette.sage : Color.secondary)
            }

            if pro.isPro {
                if let expiresAt = pro.expiresAt {
                    LabeledContent("Renews / expires", value: expiresAt.formatted(date: .abbreviated, time: .omitted))
                }
                Text("All wallpaper styles, no banner, and no interstitial ads.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Manage subscription") { pro.manageSubscriptions() }
            } else {
                Button {
                    Task { await pro.buy(monthly: true) }
                } label: {
                    HStack {
                        Text("Monthly Pro")
                        Spacer()
                        Text(pro.monthlyPrice ?? "—").foregroundStyle(.secondary)
                    }
                }
                .disabled(!pro.configured || pro.busy)

                Button {
                    Task { await pro.buy(monthly: false) }
                } label: {
                    HStack {
                        Text("Yearly Pro")
                        Spacer()
                        Text(pro.yearlyPrice ?? "—").foregroundStyle(.secondary)
                    }
                }
                .disabled(!pro.configured || pro.busy)
            }

            Button {
                Task { await pro.restorePurchases() }
            } label: {
                Label("Restore purchases", systemImage: "arrow.clockwise")
            }
            .disabled(!pro.configured || pro.busy)

            if let message = pro.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if pro.busy {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private var privacySection: some View {
        Section("Privacy") {
            if ads.privacyOptionsRequired {
                Button("Ad privacy options") { ads.showPrivacyOptions() }
            } else {
                Text("Ads are requested only after consent, and free users see at most two interstitials per session.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Text("WallVerse shows public-domain World English Bible verses. The World English Bible name is a trademark of eBible.org.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
