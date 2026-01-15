//
//  TodoMateWidget.swift
//  TodoMateWidget
//
//  Created by hs on 1/15/26.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  func placeholder(in _: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), emoji: "😀")
  }

  func getSnapshot(in _: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date(), emoji: "😀")
    completion(entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []

    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, emoji: "😀")
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let emoji: String
}

struct TodoMateWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack {
      HStack {
        Text("Time:")
        Text(entry.date, style: .time)
      }

      Text("Emoji:")
      Text(entry.emoji)
    }
  }
}

struct TodoMateWidget: Widget {
  let kind: String = "TodoMateWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(macOS 14.0, *) {
        TodoMateWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        TodoMateWidgetEntryView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("My Widget")
    .description("This is an example widget.")
  }
}
