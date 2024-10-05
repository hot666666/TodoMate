//
//  TodoListItem.swift
//  TodoMate
//
//  Created by hs on 10/5/24.
//

import SwiftUI

struct TodoListItem: View {
    @Environment(\.widgetFamily) var widgetFamily
    var todo: TodoEntity
    
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
                Text("진행 중")
                    .foregroundColor(.white)
                    .bold()
                    .lineLimit(1)
                    .fixedSize()
                Spacer()
            }
        }
        .frame(width: widgetFamily == .systemSmall ? 50 : 70)
        .background(Color.customBlue)
        .clipShape(.capsule)
        .padding(.vertical, widgetFamily == .systemSmall ? 3 : 5)
        .padding(.horizontal, 5)
        .clipShape(RoundedRectangle(cornerRadius: widgetFamily == .systemSmall ? 3 : 5))
    }
    
    @ViewBuilder
    private var content: some View {
        Text(todo.content.isEmpty ? "이름없음" : todo.content)
            .font(.title3)
    }
}
