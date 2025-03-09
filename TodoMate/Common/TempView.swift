//
//  TempWidgetTestView.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TempWidgetTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [WidgetTodo]

    @State private var newItemTitle: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("새로운 할 일", text: $newItemTitle)
                        .textFieldStyle(.roundedBorder)

                    Button("추가") {
                        addItem()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                List {
                    ForEach(items) { item in
                        Text(item.content)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("SwiftData Todo")
        }
    }

    private func addItem() {
        guard !newItemTitle.isEmpty else { return }
        let newItem = WidgetTodo(date: .now, content: newItemTitle, uid: "hs", fid: UUID().uuidString)
        modelContext.insert(newItem)
        newItemTitle = "" // 입력 필드 초기화
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
