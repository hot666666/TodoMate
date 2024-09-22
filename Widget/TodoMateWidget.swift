//
//  Widget.swift
//  Widget
//
//  Created by hs on 9/19/24.
//

import WidgetKit
import SwiftUI

struct TodoMateWidget: Widget {
    private let kind = "TodoMate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) {
            EntryView(entry: $0)
        }
        .configurationDisplayName("TodoMate Widget")
        .description("TodoMate에 등록된 오늘의 할일입니다")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TodoMateWidget()
} timeline: {
    TodoMateWidget.Entry.empty
    TodoMateWidget.Entry.placeholder
}

