import Foundation
import Testing
@testable import TodoMateApplication
import TodoMateDomain

@Suite("TodoClient")
struct TodoClientTests {
  @Test("Create validates title and persists a Project-scoped Todo")
  func createProjectTodo() async throws {
    let persistence = InMemoryProjectTodoPersistence()
    let todoID = TodoID(rawValue: "todo-1")
    let projectID = ProjectID(rawValue: "project-1")
    let instant = Date(timeIntervalSince1970: 1_786_363_200)
    let client = TodoClient.live(
      persistence: persistence,
      generateID: { todoID },
      currentAuthorID: ContentAuthorID(rawValue: "author-1"),
      now: { instant },
    )

    let createdID = try await client.create(.init(projectID: projectID, title: "  First Todo  "))
    let stored = await persistence.storedTodos()

    #expect(createdID == todoID)
    #expect(stored.count == 1)
    #expect(stored.first?.projectID == projectID)
    #expect(stored.first?.title.value == "First Todo")
    #expect(stored.first?.authorID == ContentAuthorID(rawValue: "author-1"))
  }

  @Test("Empty title fails before persistence")
  func rejectEmptyTitle() async {
    let persistence = InMemoryProjectTodoPersistence()
    let client = TodoClient.live(persistence: persistence)

    await #expect(throws: ProjectTodoTitle.ValidationError.empty) {
      try await client.create(.init(projectID: .init(rawValue: "project-1"), title: "  \n"))
    }
    #expect(await persistence.storedTodos().isEmpty)
  }
}

private actor InMemoryProjectTodoPersistence: ProjectTodoPersistence {
  private var todos: [ProjectTodo] = []

  nonisolated func observe(projectID: ProjectID) -> AsyncStream<[ProjectTodo]> {
    AsyncStream { continuation in
      Task {
        await continuation.yield(todos.filter { $0.projectID == projectID })
        continuation.finish()
      }
    }
  }

  func create(_ todo: ProjectTodo) {
    todos.append(todo)
  }

  func storedTodos() -> [ProjectTodo] {
    todos
  }
}
