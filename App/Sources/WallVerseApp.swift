import SwiftUI

@main
struct WallVerseApp: App {
    @StateObject private var model: WallpaperModel
    @StateObject private var pro: ProManager
    @StateObject private var ads: AdsManager

    init() {
        FirebaseRuntime.configure()
        let pro = ProManager(appId: WallpaperModel.appId)
        let ads = AdsManager()
        _pro = StateObject(wrappedValue: pro)
        _ads = StateObject(wrappedValue: ads)
        _model = StateObject(wrappedValue: WallpaperModel(pro: pro, ads: ads))
    }

    var body: some Scene {
        WindowGroup {
            WallpaperScreen()
                .environmentObject(model)
                .environmentObject(pro)
                .environmentObject(ads)
                .task {
                    model.start()
                    await pro.refreshEntitlement()
                }
        }
    }
}
