import ComposableArchitecture
import Foundation
import Testing
import TodoMateApplication
import TodoMateDomain
@testable import TodoMatePresentation

@MainActor
@Suite("ProjectWorkspaceFeature")
struct ProjectWorkspaceFeatureTests {
  @Test("Todo observation projects exact Project rows into State")
  func observesProjectTodos() async throws {
    let project = try makeProject(id: "project-1")
    let todo = try makeTodo(projectID: project.id)
    let store = TestStore(initialState: ProjectWorkspaceFeature.State(project: project)) {
      ProjectWorkspaceFeature()
    } withDependencies: {
      $0.todoClient = TodoClient(
        observe: { projectID in
          #expect(projectID == project.id)
          return AsyncStream { continuation in
            continuation.yield([todo])
            continuation.finish()
          }
        },
        create: { _ in todo.id },
      )
    }

    await store.send(.view(.task))
    await store.receive(.internal(.todosUpdated([todo]))) {
      $0.todos = [todo]
    }
  }

  @Test("Create sends a Project-scoped command and clears the draft")
  func createsTodo() async throws {
    let project = try makeProject(id: "project-1")
    let todoID = TodoID(rawValue: "todo-1")
    let store = TestStore(initialState: ProjectWorkspaceFeature.State(project: project)) {
      ProjectWorkspaceFeature()
    } withDependencies: {
      $0.todoClient = TodoClient(
        observe: { _ in AsyncStream { $0.finish() } },
        create: { command in
          #expect(command.projectID == project.id)
          #expect(command.title == "First Todo")
          return todoID
        },
      )
    }

    await store.send(.view(.todoDraftChanged("First Todo"))) {
      $0.todoDraft = "First Todo"
    }
    await store.send(.view(.createTodoTapped)) {
      $0.isCreatingTodo = true
    }
    await store.receive(.internal(.todoCreated(todoID))) {
      $0.isCreatingTodo = false
      $0.todoDraft = ""
    }
  }

  @Test("Empty Todo titles cannot start a mutation")
  func rejectsEmptyTodoTitle() async throws {
    let project = try makeProject(id: "project-1")
    var state = ProjectWorkspaceFeature.State(project: project)
    state.todoDraft = "  \n"
    let store = TestStore(initialState: state) {
      ProjectWorkspaceFeature()
    } withDependencies: {
      $0.todoClient.create = { _ in
        Issue.record("Todo creation must not be called for an empty title")
        return TodoID(rawValue: "unexpected")
      }
    }

    #expect(!store.state.canCreateTodo)
    await store.send(.view(.createTodoTapped))
  }

  @Test("Project switch cancels the previous Todo observation and resets projection")
  func projectSwitchCancelsObservation() async throws {
    let first = try makeProject(id: "first")
    let second = try makeProject(id: "second")
    let cancellation = CancellationProbe()
    let store = TestStore(initialState: ProjectWorkspaceFeature.State(project: first)) {
      ProjectWorkspaceFeature()
    } withDependencies: {
      $0.todoClient = TodoClient(
        observe: { _ in
          AsyncStream { continuation in
            continuation.onTermination = { _ in
              Task { await cancellation.markCancelled() }
            }
          }
        },
        create: { _ in .init(rawValue: "unused") },
      )
    }

    await store.send(.view(.task))
    await store.send(.internal(.projectChanged(second))) {
      $0.project = second
    }
    await store.finish()
    #expect(await cancellation.isCancelled())
  }

  @Test("Project switch cancels an in-flight Todo creation")
  func projectSwitchCancelsCreation() async throws {
    let first = try makeProject(id: "first")
    let second = try makeProject(id: "second")
    let cancellation = CancellationProbe()
    var state = ProjectWorkspaceFeature.State(project: first)
    state.todoDraft = "First Todo"
    let store = TestStore(initialState: state) {
      ProjectWorkspaceFeature()
    } withDependencies: {
      $0.todoClient = TodoClient(
        observe: { _ in AsyncStream { $0.finish() } },
        create: { _ in
          try await withTaskCancellationHandler {
            try await Task.sleep(for: .seconds(60))
            return TodoID(rawValue: "unreachable")
          } onCancel: {
            Task { await cancellation.markCancelled() }
          }
        },
      )
    }

    await store.send(.view(.createTodoTapped)) {
      $0.isCreatingTodo = true
    }
    await store.send(.internal(.projectChanged(second))) {
      $0.project = second
      $0.todoDraft = ""
      $0.isCreatingTodo = false
    }
    await store.finish()
    #expect(await cancellation.isCancelled())
  }

  private func makeProject(id: String) throws -> Project {
    try Project(
      id: .init(rawValue: id),
      name: ProjectName("Daily"),
      lifecycle: .local,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
  }

  private func makeTodo(projectID: ProjectID) throws -> ProjectTodo {
    try ProjectTodo(
      id: .init(rawValue: "todo-1"),
      projectID: projectID,
      authorID: .init(rawValue: "author-1"),
      title: .init("First Todo"),
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
  }
}

private actor CancellationProbe {
  private var cancelled = false

  func markCancelled() {
    cancelled = true
  }

  func isCancelled() -> Bool {
    cancelled
  }
}
