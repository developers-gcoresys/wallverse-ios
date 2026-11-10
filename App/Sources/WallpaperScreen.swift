import SwiftUI
import WallVerseCore

enum WallVersePalette {
    static let cream = Color(hex: "F7F4ED")
    static let ink = Color(hex: "26352E")
    static let sage = Color(hex: "718477")
    static let muted = Color(hex: "85877E")
}

extension Color {
    init(hex: String) {
        self.init(uiColor: HexColor.uiColor(hex))
    }
}

struct WallpaperScreen: View {
    @EnvironmentObject private var model: WallpaperModel
    @EnvironmentObject private var pro: ProManager
    @EnvironmentObject private var ads: AdsManager
    @State private var sharePayload: SharePayload?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    stylePicker
                    preview
                    actions
                    status
                    if ads.privacyOptionsRequired {
                        Button("Ad privacy options") { ads.showPrivacyOptions() }
                            .font(.footnote)
                            .foregroundStyle(WallVersePalette.sage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
            .background(WallVersePalette.cream)

            if !pro.isPro && ads.consentReady {
                Divider()
                BannerAdView(unitID: ads.bannerUnitID)
                    .frame(height: 50)
                    .background(WallVersePalette.cream)
            }
        }
        .background(WallVersePalette.cream.ignoresSafeArea())
        .sheet(isPresented: $model.showingPro) {
            ProSheet()
                .environmentObject(model)
                .environmentObject(pro)
                .environmentObject(ads)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: [payload.image])
        }
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                Text(toast)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(WallVersePalette.ink.opacity(0.92), in: Capsule())
                    .padding(.bottom, 70)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.toast)
        .onChange(of: model.toast) { _, value in
            guard let value else { return }
            Task {
                try? await Task.sleep(for: .seconds(4))
                if model.toast == value { model.toast = nil }
            }
        }
        .onChange(of: pro.isPro) { _, _ in
            model.enforceEntitlement()
        }
        .task {
            model.start()
            await pro.refreshEntitlement()
            model.enforceEntitlement()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WallVerse")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(WallVersePalette.ink)
                Text("Verse on your lock screen")
                    .font(.caption)
                    .foregroundStyle(WallVersePalette.muted)
            }
            Spacer()
            Button {
                model.showingPro = true
            } label: {
                Text(pro.isPro ? "Pro ✓" : "Go Pro")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WallVersePalette.sage)
            }
        }
        .padding(.top, 14)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WallVersePalette.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WallpaperStyle.allCases) { style in
                        let locked = style.isPro && !pro.isPro
                        Button {
                            model.select(style)
                        } label: {
                            HStack(spacing: 4) {
                                Text(style.label)
                                if locked {
                                    Image(systemName: "lock.fill").font(.caption2)
                                }
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                model.style == style ? WallVersePalette.sage : Color.white,
                                in: Capsule()
                            )
                            .foregroundStyle(model.style == style ? Color.white : WallVersePalette.ink)
                            .overlay(Capsule().stroke(WallVersePalette.sage.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var preview: some View {
        ZStack {
            if let image = model.preview {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(hex: model.style.backgroundHex)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .accessibilityLabel("Preview of \(model.currentVerse.reference)")
        .accessibilityAddTraits(.isImage)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation { model.newVerse() }
            } label: {
                Text("New verse")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(WallVersePalette.ink, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button {
                    model.saveToPhotos()
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(WallVersePalette.sage.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(WallVersePalette.ink)

                Button {
                    sharePayload = SharePayload(image: model.exportImage())
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(WallVersePalette.sage.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(WallVersePalette.ink)
            }
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iOS does not let an app set the wallpaper directly. Save the image, open Photos, tap Share, then choose **Use as Wallpaper**.")
                .font(.caption)
                .foregroundStyle(WallVersePalette.muted)

            Text(pro.isPro
                 ? "Pro: all styles unlocked and ads removed."
                 : "Free: two styles with ads. Go Pro for all styles and no ads.")
                .font(.caption)
                .foregroundStyle(WallVersePalette.muted)

            if let error = ads.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(WallVersePalette.muted)
            }
        }
    }
}
