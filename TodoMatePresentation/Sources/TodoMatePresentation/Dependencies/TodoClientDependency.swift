import ComposableArchitecture
import TodoMateApplication

private enum TodoClientKey: DependencyKey {
  static let liveValue = TodoClient(
    observe: { _ in AsyncStream { $0.finish() } },
    create: { _ in throw MissingTodoClient() },
  )
  static let testValue = liveValue
}

public extension DependencyValues {
  var todoClient: TodoClient {
    get { self[TodoClientKey.self] }
    set { self[TodoClientKey.self] = newValue }
  }
}

private struct MissingTodoClient: Error {}
