import Foundation
import SwiftUI
import UIKit
import WallVerseCore

@MainActor
final class WallpaperModel: ObservableObject {
    static let appId = "wallverse"

    @Published private(set) var verses: [WallpaperVerse]
    @Published private(set) var index: Int
    @Published private(set) var preview: UIImage?
    @Published var style: WallpaperStyle {
        didSet {
            defaults.set(style.rawValue, forKey: Keys.style)
            refreshPreview()
        }
    }
    @Published var showingPro = false
    @Published var toast: String?

    let pro: ProManager
    let ads: AdsManager
    private let defaults = UserDefaults.standard
    private var adSession = WallpaperAdSession()
    private var started = false

    init(pro: ProManager, ads: AdsManager) {
        self.pro = pro
        self.ads = ads
        verses = Self.loadVerses()
        index = min(defaults.integer(forKey: Keys.index), max(0, verses.count - 1))
        if let saved = defaults.string(forKey: Keys.style), let style = WallpaperStyle(rawValue: saved) {
            self.style = style
        } else {
            style = .softLight
        }
        refreshPreview()
    }

    var currentVerse: WallpaperVerse {
        verses[index % max(1, verses.count)]
    }

    func start() {
        guard !started else { return }
        started = true
        pro.start()
        ads.start()
    }

    func newVerse() {
        guard !verses.isEmpty else { return }
        index = (index + 1) % verses.count
        defaults.set(index, forKey: Keys.index)
        refreshPreview()
        if !pro.isPro, adSession.recordNewVerse(at: Date()) {
            if ads.presentInterstitialIfAvailable() {
                adSession.markAdShown(at: Date())
            }
        }
    }

    func select(_ style: WallpaperStyle) {
        guard !style.isPro || pro.isPro else {
            showingPro = true
            return
        }
        self.style = style
    }

    func refreshPreview() {
        preview = WallpaperRenderer.preview(for: currentVerse, style: style)
    }

    func exportImage() -> UIImage {
        WallpaperRenderer.export(for: currentVerse, style: style)
    }

    func saveToPhotos() {
        let image = exportImage()
        PhotoSaver.shared.save(image) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.toast = "Saved to Photos. Set it from Photos → Share → Use as Wallpaper."
                case .failure:
                    self?.toast = "Could not save the image. Allow Photos access in Settings."
                }
            }
        }
    }

    private static func loadVerses() -> [WallpaperVerse] {
        guard let url = Bundle.main.url(forResource: "verses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? VerseLibrary.load(data: data),
              !verses.isEmpty else {
            return VerseLibrary.fallback
        }
        return verses
    }

    private enum Keys {
        static let style = "wallverse.style"
        static let index = "wallverse.index"
    }
}

@MainActor
final class PhotoSaver: NSObject {
    static let shared = PhotoSaver()
    private var completion: ((Result<Void, Error>) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc private func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
        let callback = completion
        completion = nil
        if let error {
            callback?(.failure(error))
        } else {
            callback?(.success(()))
        }
    }
}
