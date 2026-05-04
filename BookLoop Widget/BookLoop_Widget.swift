import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), title: "Book Title", isPlaying: false, progressFraction: 0.3, thumbnailData: nil)
    }

    // Helper to ensure image data isn't too large for the widget
    private func safelyDownsampledData(_ data: Data?) -> Data? {
        guard let data = data, let image = UIImage(data: data) else { return nil }
        // If the legacy image is too large, it crashes widget archival.
        // Discard it. The updated iOS app will sync a properly sized 60x60 image.
        if image.size.width > 100 || image.size.height > 100 {
            return nil
        }
        return data
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let defaults = UserDefaults(suiteName: "group.com.bookloop")
        let title = defaults?.string(forKey: "title") ?? "No track"
        let isPlaying = defaults?.bool(forKey: "isPlaying") ?? false
        let progressFraction = defaults?.double(forKey: "progressFraction") ?? 0.0
        let thumbnailData = safelyDownsampledData(defaults?.data(forKey: "thumbnailData"))
        
        let entry = SimpleEntry(date: Date(), title: title, isPlaying: isPlaying, progressFraction: progressFraction, thumbnailData: thumbnailData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let defaults = UserDefaults(suiteName: "group.com.bookloop")
        let title = defaults?.string(forKey: "title") ?? "No track"
        let isPlaying = defaults?.bool(forKey: "isPlaying") ?? false
        let progressFraction = defaults?.double(forKey: "progressFraction") ?? 0.0
        let thumbnailData = safelyDownsampledData(defaults?.data(forKey: "thumbnailData"))

        let entry = SimpleEntry(date: Date(), title: title, isPlaying: isPlaying, progressFraction: progressFraction, thumbnailData: thumbnailData)
        
        // Refresh periodically, but mostly we rely on reloadAllTimelines() when data changes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let isPlaying: Bool
    let progressFraction: Double
    let thumbnailData: Data?
    var relevance: TimelineEntryRelevance? {
        TimelineEntryRelevance(score: isPlaying ? 100.0 : 0.0)
    }
}

struct BookLoop_WidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        Gauge(value: entry.progressFraction) {
            EmptyView()
        } currentValueLabel: {
            if let data = entry.thumbnailData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "music.note")
            }
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.green)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "bookloop://"))
    }
}

struct BookLoop_Widget: Widget {
    let kind: String = "BookLoop_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BookLoop_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("BookLoop")
        .description("Quick access to your current audiobook.")
        .supportedFamilies([.accessoryCircular])
    }
}
