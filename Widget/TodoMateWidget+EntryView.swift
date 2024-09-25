//
//  TodoMateWidget+EntryView.swift
//  LearnWidgetKit
//
//  Created by hs on 9/11/24.
//

import SwiftUI

extension TodoMateWidget {
    struct EntryView: View {
        let entry: Entry

        var body: some View {
            VStack(alignment: .leading) {
                contentView
            }
            .containerBackground(Color.customGrayBg, for: .widget)
        }
    }
}

// MARK: - Content
extension TodoMateWidget.EntryView {
    @ViewBuilder
    private var contentView: some View {
        ForEach(entry.todos) { todo in
            TodoListItem(todo: todo)
        }
        
        if entry.todos.isEmpty {
            Text("진행 중인 투두가 없습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - TodoListItem
fileprivate struct TodoListItem: View {
    var todo: Todo
    
    var body: some View {
        HStack {
            status
            content
            Spacer()
        }
    }

    @ViewBuilder
    private var status: some View {
        Button(action: { }) {
            HStack {
                Spacer()
                Text(todo.status.rawValue)
                    .foregroundColor(.white)
                    .bold()
                    .lineLimit(1)
                    .fixedSize()
                Spacer()
            }
        }
        .frame(width: 70)
        .background(todo.status.color)
        .clipShape(.capsule)
        .padding(5)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    @ViewBuilder
    private var content: some View {
        Text(todo.content.isEmpty ? "이름없음" : todo.content)
            .font(.title3)
    }
}

