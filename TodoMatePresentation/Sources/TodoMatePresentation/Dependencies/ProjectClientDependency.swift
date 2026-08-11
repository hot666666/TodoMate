import ComposableArchitecture
import TodoMateApplication

private enum ProjectClientKey: DependencyKey {
  static let liveValue = ProjectClient(
    snapshots: { AsyncStream { $0.finish() } },
    createLocal: { _ in throw MissingProjectClient() },
    select: { _ in throw MissingProjectClient() },
  )
  static let testValue = liveValue
}

public extension DependencyValues {
  var projectClient: ProjectClient {
    get { self[ProjectClientKey.self] }
    set { self[ProjectClientKey.self] = newValue }
  }
}

private struct MissingProjectClient: Error {}
