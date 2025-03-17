//
//  FirestoreTodoRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

protocol TodoRepositoryType {
  func createTodo(_ todo: TodoDTO) async throws -> TodoDTO
  func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO]
  func fetchTodos(groupId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO]
  func updateTodo(todo: TodoDTO) async throws
  func deleteTodo(todoId: String) async throws

  // MARK: - Repository for the Store

  func create(_ todo: TodoDTO) throws -> TodoDTO
  func readAll() async throws -> [TodoDTO]
  func update(_ todo: TodoDTO) throws
  func delete(id: String)
}

enum TodoRepositoryError: Error {
  case createError
  case readError
  case updateError
  case deleteError
}

#if !PREVIEW
  final class FirestoreTodoRepository: TodoRepositoryType {
    private let reference: FirestoreReference

    init(reference: FirestoreReference = .shared) {
      self.reference = reference
    }

    func createTodo(_ todo: TodoDTO) async throws -> TodoDTO {
      let collectionRef = reference.todoCollection()
      let newDocReference = try collectionRef.addDocument(from: todo)
      let document = try await newDocReference.getDocument()
      return try document.data(as: TodoDTO.self)
    }

    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
      let snapshot = try await reference.todoCollection()
        .whereField("date", isGreaterThanOrEqualTo: startDate)
        .whereField("date", isLessThanOrEqualTo: endDate)
        .whereField("uid", isEqualTo: userId)
        .getDocuments()

      return snapshot.documents.compactMap { document -> TodoDTO? in
        do {
          return try document.data(as: TodoDTO.self)
        } catch {
          print("Error decoding todo: \(error)")
          return nil
        }
      }
    }

    // TODO: - 실제 GroupId로 조회하는 로직으로 변경
    func fetchTodos(groupId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
      let snapshot = try await reference.todoCollection()
        .whereField("date", isGreaterThanOrEqualTo: startDate)
        .whereField("date", isLessThanOrEqualTo: endDate)
        .getDocuments()

      return snapshot.documents.compactMap { document -> TodoDTO? in
        do {
          return try document.data(as: TodoDTO.self)
        } catch {
          print("Error decoding todo: \(error)")
          return nil
        }
      }
    }

    func updateTodo(todo: TodoDTO) async throws {
      guard let todoId = todo.id else { return }
      let todoDocRef = reference.todoCollection().document(todoId)
      try todoDocRef.setData(from: todo)
    }

    func deleteTodo(todoId: String) async throws {
      let todoDocRef = reference.todoCollection().document(todoId)
      /// 삭제 전에 실시간 업데이트를 위해 마지막 수정 시간을 업데이트하고 삭제
      try await todoDocRef.updateData(["lastModifiedAt": Date.now])
      try await todoDocRef.delete()
    }

    // MARK: - Repository for the Store

    func create(_ todo: TodoDTO) throws -> TodoDTO {
      do {
        let document = try reference.todoCollection().addDocument(from: todo)
        let fid = document.documentID
        var todo = todo
        todo.id = fid
        return todo
      } catch {
        throw TodoRepositoryError.createError
      }
    }

    func readAll() async throws -> [TodoDTO] {
      // 날짜 관련 쿼리 분리, 모든 유저가 같은 그룹인 상황 가정
      let calendar = Calendar.current
      let today: Date = .now
      let startDate = calendar.startOfDay(for: today)
      let tomorrow = calendar.date(byAdding: .day, value: 1, to: startDate)!
      let endDate = calendar.date(byAdding: .second, value: -1, to: tomorrow)!

      do {
        let querySnapshot = try await reference.todoCollection()
          .whereField("date", isGreaterThanOrEqualTo: startDate)
          .whereField("date", isLessThanOrEqualTo: endDate)
          .getDocuments()

        return querySnapshot.documents.compactMap { document -> TodoDTO? in
          do {
            return try document.data(as: TodoDTO.self)
          } catch {
            print("Error decoding todo: \(error)")
            return nil
          }
        }
      } catch {
        throw TodoRepositoryError.readError
      }
    }

    func update(_ todo: TodoDTO) throws {
      guard let todoId = todo.id else {
        throw TodoRepositoryError.updateError
      }

      do {
        try reference
          .todoCollection()
          .document(todoId)
          .setData(from: todo, merge: true)
      } catch {
        throw TodoRepositoryError.updateError
      }
    }

    func delete(id: String) {
      reference
        .todoCollection()
        .document(id)
        .delete()
    }
  }
#else
  final class FirestoreTodoRepository: TodoRepositoryType {
    func createTodo(_ todo: TodoDTO) async throws -> TodoDTO {
      print("[Creating Todo] - \(todo)")

      return .stub
    }

    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
      print("[Fetcing Todo] - \(userId)")

      return TodoDTO.stubs.filter { $0.uid == userId && startDate ... endDate ~= $0.date }
    }

    func fetchTodos(groupId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
      print("[Fetcing Todo] - \(groupId)")

      return TodoDTO.stubs.filter { startDate ... endDate ~= $0.date }
    }

    func updateTodo(todo: TodoDTO) async throws {
      print("[Updating Todo] - \(todo)")
    }

    func deleteTodo(todoId: String) async throws {
      print("[Deleting Todo] - \(todoId)")
    }

    // MARK: - Repository for the Store

    func create(_ todo: TodoDTO) throws -> TodoDTO {
      .stub
    }

    func readAll() async throws -> [TodoDTO] {
      TodoDTO.stubs
    }

    func update(_ todo: TodoDTO) throws {}

    func delete(id: String) {}
  }
#endif
