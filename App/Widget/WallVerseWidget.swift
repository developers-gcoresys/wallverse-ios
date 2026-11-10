import SwiftUI
import WidgetKit

private struct WidgetVerse: Codable {
    let reference: String
    let text: String
}

private enum WidgetContent {
    static let verses: [WidgetVerse] = {
        guard let url = Bundle.main.url(forResource: "verses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode([WidgetVerse].self, from: data) else {
            return []
        }
        return loaded
    }()

    static let palettes: [(background: Color, foreground: Color)] = [
        (Color(red: 0.97, green: 0.96, blue: 0.93), Color(red: 0.15, green: 0.21, blue: 0.18)),
        (Color(red: 0.06, green: 0.09, blue: 0.13), Color(red: 0.96, green: 0.95, blue: 0.91)),
        (Color(red: 0.23, green: 0.18, blue: 0.12), Color(red: 0.96, green: 0.85, blue: 0.65)),
        (Color(red: 0.06, green: 0.16, blue: 0.20), Color(red: 0.81, green: 0.91, blue: 0.89)),
        (Color(red: 0.12, green: 0.16, blue: 0.11), Color(red: 0.84, green: 0.91, blue: 0.78))
    ]

    static func verse(for date: Date) -> (index: Int, verse: WidgetVerse)? {
        guard !verses.isEmpty else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let days = Int(calendar.startOfDay(for: date).timeIntervalSinceReferenceDate / 86_400)
        let index = ((days % verses.count) + verses.count) % verses.count
        return (index, verses[index])
    }
}

struct WallVerseEntry: TimelineEntry {
    let date: Date
    let reference: String
    let text: String
    let themeIndex: Int
}

struct WallVerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> WallVerseEntry {
        WallVerseEntry(
            date: Date(),
            reference: "John 3:16",
            text: "For God so loved the world, that he gave his one and only Son…",
            themeIndex: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WallVerseEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WallVerseEntry>) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let entries = (0..<7).compactMap { offset -> WallVerseEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return entry(for: day)
        }
        completion(Timeline(entries: entries.isEmpty ? [entry(for: Date())] : entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> WallVerseEntry {
        guard let match = WidgetContent.verse(for: date) else {
            return WallVerseEntry(date: date, reference: "WallVerse", text: "Open the app to choose a verse.", themeIndex: 0)
        }
        return WallVerseEntry(
            date: date,
            reference: match.verse.reference,
            text: match.verse.text,
            themeIndex: match.index % WidgetContent.palettes.count
        )
    }
}

struct WallVerseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WallVerseEntry

    var body: some View {
        let palette = WidgetContent.palettes[entry.themeIndex % WidgetContent.palettes.count]
        VStack(alignment: .center, spacing: 10) {
            Spacer(minLength: 0)
            Text(entry.text)
                .font(.system(size: family == .systemSmall ? 15 : 18, design: .serif))
                .multilineTextAlignment(.center)
                .lineLimit(family == .systemSmall ? 6 : 5)
                .minimumScaleFactor(0.75)
                .foregroundStyle(palette.foreground)
            Text(entry.reference)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(palette.foreground.opacity(0.75))
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            palette.background
        }
    }
}

@main
struct WallVerseWidget: Widget {
    let kind = "WallVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WallVerseProvider()) { entry in
            WallVerseWidgetView(entry: entry)
        }
        .configurationDisplayName("Verse of the day")
        .description("A wallpaper-style verse that changes each day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
