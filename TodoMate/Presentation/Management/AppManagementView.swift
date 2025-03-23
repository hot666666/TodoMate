//
//  AppManagementView.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import SwiftData
import SwiftUI
import WidgetKit

private struct MyGroupBox<Content: View>: View {
  private let title: String
  private let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    GroupBox {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.headline)
        content
      }
    }
  }
}

struct AppManagementView: View {
  private let columns = [
    GridItem(.flexible(), alignment: .topLeading),
    GridItem(.flexible(), alignment: .topLeading),
  ]

  var body: some View {
    ScrollView(showsIndicators: false) {
      LazyVGrid(columns: columns) {
        MyGroupBox("AuthenticatedUser") {
          AuthenticatedUserView()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        MyGroupBox("Widget") {
          WidgetView()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        MyGroupBox("Todos(Today)") {
          TodosView()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding()
    }
  }
}

@Observable
class TodayTodoStore {
  private let todoRepository: TodoRepositoryType

  var todos: [Todo] = []

  init(todoRepository: TodoRepositoryType = FirestoreTodoRepository()) {
    self.todoRepository = todoRepository
  }

  @MainActor
  func fetchTodos() async {
    do {
      todos = try await todoRepository.readAll().compactMap { try? $0.toModel() }
    } catch {
      print(error.localizedDescription)
    }
  }
}

// MARK: - TodosView

private struct TodosView: View {
  @State private var store: TodayTodoStore = .init()

  var body: some View {
    Group {
      if store.todos.isEmpty {
        Text("오늘 할일 없음")
      }

      ForEach(store.todos) { todo in
        VStack(alignment: .leading) {
          Text(todo.content)
          Text(todo.uid)
        }
      }
    }
    .task {
      await store.fetchTodos()
    }
  }
}

// MARK: - AuthenticatedUserView

private struct AuthenticatedUserView: View {
  @Environment(AuthManager.self) private var authManager

  var body: some View {
    VStack(alignment: .leading) {
      if let user = authManager.authenticatedUser {
        Text(user.uid)
        if let gid = user.gid {
          Text(gid)
        } else {
          Text("그룹 없음")
        }
      } else {
        Text("사용자 정보가 없습니다.")
      }
    }
  }
}

// MARK: - WidgetView

private struct WidgetView: View {
  @Query private var todos: [WidgetTodo]
  @Environment(\.modelContext) private var container

  var body: some View {
    if todos.isEmpty {
      Text("진행 중인 나의 Todo가 없습니다.")
    }

    ForEach(todos) { todo in
      todoRow(for: todo)
    }

    Divider()

    HStack {
      Button("+") {
        createTodo()
      }

      Button("위젯 업데이트") {
        try? container.save()
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }

  private func todoRow(for todo: WidgetTodo) -> some View {
    HStack {
      Button("삭제") {
        deleteTodo(todo)
      }

      VStack(alignment: .leading) {
        Text(todo.content)
        Text(todo.uid)
        Text(todo.date.toYYYYMMDDString())
        Text(todo.fid)
      }
    }
  }

  // CREATE
  private func createTodo() {
    let newTodo = WidgetTodo(
      date: .now,
      content: "진행 중 TODO",
      uid: "test-uid",
      fid: UUID().uuidString
    )
    container.insert(newTodo)
  }

  // DELETE
  private func deleteTodo(_ todo: WidgetTodo) {
    container.delete(todo)
  }
}

#Preview {
  AppManagementView()
    .frame(width: 300, height: 400)
    .environment(MessageStore.get)
    .environment(AuthManager.stub)
    .modelContainer(.forPreview())
}
