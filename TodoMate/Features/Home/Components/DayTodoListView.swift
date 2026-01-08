//
//  DayTodoListView.swift
//  TodoMate
//
//  Created by agent on 1/7/26.
//

import SimpleOverlaySystem
import SwiftUI

/// 특정 날짜의 모든 할 일 목록을 보여주는 오버레이 뷰
struct DayTodoListView: View {
  @Environment(\.overlayManager) private var overlay

  let date: Date
  let todos: [ViewTodo]
  let onTapTodo: (ViewTodo) -> Void

  private var title: String {
    date.formatted(.dateTime.month().day().weekday(.wide))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title)
        .font(.title2)
        .bold()

      if todos.isEmpty {
        Text("이 날짜에 등록된 일정이 없습니다.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        List {
          ForEach(todos) { todo in
            TaskCard(task: todo, style: .compact)
              .onTapGesture {
                onTapTodo(todo)
              }
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
      }
    }
    .padding()
    .frame(width: 400, height: min(CGFloat(todos.count * 50 + 100), 500))
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1),
    )
    .shadow(color: .black.opacity(0.2), radius: 10)
    .onKeyPress(.escape) {
      overlay?.dismissTop()
      return .handled
    }
  }
}

#Preview {
  DayTodoListView(
    date: Date(),
    todos: [],
    onTapTodo: { _ in },
  )
  .padding()
}
