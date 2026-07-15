import WidgetKit
import SwiftUI

struct QuickCaptureEntry: TimelineEntry {
    let date: Date
}

struct QuickCaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickCaptureEntry {
        QuickCaptureEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickCaptureEntry) -> Void) {
        completion(QuickCaptureEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureEntry>) -> Void) {
        completion(Timeline(entries: [QuickCaptureEntry(date: .now)], policy: .never))
    }
}

/// Tapping the widget opens Aware with the "What happened?" field focused.
struct QuickCaptureWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickCaptureWidget", provider: QuickCaptureProvider()) { _ in
            QuickCaptureWidgetView()
        }
        .configurationDisplayName("Quick capture")
        .description("One tap to write down what just happened.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickCaptureWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.appAccent)
            Spacer()
            Text("What happened?")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Color.appInk)
            Text("Tap to capture this moment")
                .font(.caption2)
                .foregroundStyle(Color.appMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color.appCard
        }
        .widgetURL(URL(string: "aware://capture"))
    }
}
