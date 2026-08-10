import Foundation
import TodoMateData
import TodoMateDomain

private struct ProjectionProbeResult: Codable {
  let processIdentifier: Int32
  let todos: [Todo]
}

@main
private enum GRDBReadOnlyProjectionProbe {
  static func main() async throws {
    guard CommandLine.arguments.count == 3 else {
      throw ProbeError.invalidArguments
    }

    let databaseURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let ownerID = CommandLine.arguments[2]
    guard let database = try GRDBReadOnlyDatabase(storage: .file(databaseURL)) else {
      throw ProbeError.databaseUnavailable
    }

    let todos = try await GRDBTodoReader(database: database)
      .fetch(query: TodoQuery().owner(userId: ownerID))
    let result = ProjectionProbeResult(
      processIdentifier: ProcessInfo.processInfo.processIdentifier,
      todos: todos,
    )
    let data = try JSONEncoder().encode(result)
    try FileHandle.standardOutput.write(contentsOf: data)
  }
}

private enum ProbeError: Error {
  case invalidArguments
  case databaseUnavailable
}
