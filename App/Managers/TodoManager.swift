//
//  TodoManager.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

@MainActor
@Observable
final class TodoManager {
  private let db: Firestore
  private let authManager: AuthManager

  private(set) var myTodos: [Todo] = []
  private(set) var groupTodos: [Todo] = []

  init(db: Firestore, authManager: AuthManager) {
    self.db = db
    self.authManager = authManager
  }

  // MARK: - Create

  func createTodo(content: String, detail: String = "", date: Date = .now) async throws {
    guard let userId = authManager.currentUser?.id else {
      Log.warning("Cannot create todo: no authenticated user", category: .sync)
      return
    }

    let groupId = authManager.currentUser?.groupId

    let todo = Todo(
      groupId: groupId,
      owner: userId,
      content: content,
      detail: detail,
      date: date,
    )

    do {
      let docRef = try db.collection("todos").addDocument(from: todo)
      Log.info("Todo created: \(docRef.documentID)", category: .sync)
    } catch {
      Log.error("Failed to create todo: \(error)", category: .sync)
      throw error
    }
  }

  // MARK: - Read

  /// 내 투두만 조회
  func fetchMyTodos() async {
    guard let userId = authManager.currentUser?.id else {
      myTodos = []
      return
    }

    do {
      let snapshot = try await db.collection("todos")
        .whereField("owner", isEqualTo: userId)
        .order(by: "date", descending: true)
        .getDocuments()

      myTodos = snapshot.documents.compactMap { document in
        do {
          return try document.data(as: Todo.self)
        } catch {
          Log.error(
            "Failed to decode my todo: \(error.localizedDescription), documentID: \(document.documentID)",
            category: .sync,
          )
          return nil
        }
      }
    } catch {
      Log.error("Failed to fetch my todos: \(error)", category: .sync)
      myTodos = []
    }
  }

  /// 그룹 투두 조회 (협업 뷰)
  func fetchGroupTodos() async {
    guard let groupId = authManager.currentUser?.groupId else {
      groupTodos = []
      return
    }

    do {
      let snapshot = try await db.collection("todos")
        .whereField("groupId", isEqualTo: groupId)
        .order(by: "date", descending: true)
        .getDocuments()

      groupTodos = snapshot.documents.compactMap { document in
        do {
          return try document.data(as: Todo.self)
        } catch {
          Log.error(
            "Failed to decode group todo: \(error.localizedDescription), documentID: \(document.documentID)",
            category: .sync,
          )
          return nil
        }
      }
    } catch {
      Log.error("Failed to fetch group todos: \(error)", category: .sync)
      groupTodos = []
    }
  }

  // MARK: - Update

  func updateTodo(_ todo: Todo) async throws {
    guard let todoId = todo.id else {
      Log.warning("Cannot update todo: missing id", category: .sync)
      return
    }

    guard isOwner(of: todo) else {
      Log.warning("Cannot update todo: not owner", category: .sync)
      return
    }

    do {
      try db.collection("todos").document(todoId).setData(from: todo, merge: true)
      Log.info("Todo updated: \(todoId)", category: .sync)
    } catch {
      Log.error("Failed to update todo: \(error)", category: .sync)
      throw error
    }
  }

  // MARK: - Delete

  func deleteTodo(_ todo: Todo) async throws {
    guard let todoId = todo.id else {
      Log.warning("Cannot delete todo: missing id", category: .sync)
      return
    }

    guard isOwner(of: todo) else {
      Log.warning("Cannot delete todo: not owner", category: .sync)
      return
    }

    do {
      try await db.collection("todos").document(todoId).delete()
      Log.info("Todo deleted: \(todoId)", category: .sync)
    } catch {
      Log.error("Failed to delete todo: \(error)", category: .sync)
      throw error
    }
  }

  // MARK: - Helpers

  private func isOwner(of todo: Todo) -> Bool {
    todo.isOwned(by: authManager.currentUser?.id)
  }
}
