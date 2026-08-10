import Darwin
import Foundation
import GRDB
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("GRDB Read-Only Cross-Process Tests", .serialized)
struct GRDBReadOnlyCrossProcessTests {
  @Test("A separate process reads the committed projection through the read-only API")
  func separateProcessReadsCommittedProjection() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("read-only-cross-process-\(UUID().uuidString)", isDirectory: true)
    let databaseURL = directoryURL.appendingPathComponent("TodoMate.sqlite")
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    let writableDatabase = try GRDBDatabase(storage: .file(databaseURL))
    let repository = GRDBTodoRepository(database: writableDatabase)
    let expectedTodo = Self.expectedTodo()
    try await repository.create(expectedTodo)

    let result = try await Self.runProbe(databaseURL: databaseURL, ownerID: expectedTodo.owner)
    #expect(result.processIdentifier != ProcessInfo.processInfo.processIdentifier)
    #expect(result.todos == [expectedTodo])

    try await Self.assertReadOnly(
      databaseURL: databaseURL,
      expectedTodo: expectedTodo,
      repository: repository,
    )
  }

  private static func expectedTodo() -> Todo {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    return Todo(
      id: "cross-process-todo",
      content: "Visible to the widget process",
      status: .inProgress,
      detail: "Committed before the child starts",
      date: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
      owner: "cross-process-owner",
    )
  }

  private static func runProbe(databaseURL: URL, ownerID: String) async throws -> ProjectionProbeResult {
    let probeURL = try Self.probeExecutableURL()
    let process = Process()
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.executableURL = probeURL
    process.arguments = [databaseURL.path, ownerID]
    process.standardOutput = standardOutput
    process.standardError = standardError

    try process.run()
    defer { Self.forceTerminateIfRunning(process) }
    guard try await Self.waitForExit(process, timeout: .seconds(10)) else {
      await Self.terminate(process)
      throw ProbeExecutionError.timedOut
    }

    let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
    let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
    let errorOutput = String(data: errorData, encoding: .utf8) ?? "<non-UTF8 stderr>"
    guard process.terminationReason == .exit, process.terminationStatus == 0 else {
      throw ProbeExecutionError.failed(status: process.terminationStatus, standardError: errorOutput)
    }
    return try JSONDecoder().decode(ProjectionProbeResult.self, from: outputData)
  }

  private static func assertReadOnly(
    databaseURL: URL,
    expectedTodo: Todo,
    repository: GRDBTodoRepository,
  ) async throws {
    guard let readOnlyDatabase = try GRDBReadOnlyDatabase(storage: .file(databaseURL)) else {
      Issue.record("Expected the committed database to remain available")
      return
    }
    do {
      try await readOnlyDatabase.reader.read { databaseConnection in
        try databaseConnection.execute(
          sql: "DELETE FROM todo WHERE id = ?",
          arguments: [expectedTodo.id],
        )
      }
      Issue.record("Expected the read-only database to reject a delete")
    } catch let error as DatabaseError {
      #expect(error.resultCode == .SQLITE_READONLY)
    } catch {
      Issue.record("Expected SQLITE_READONLY, got: \(error)")
    }
    let persistedTodos = try await repository.readAll(
      query: TodoQuery().owner(userId: expectedTodo.owner),
      useCache: false,
    )
    #expect(persistedTodos == [expectedTodo])
  }

  private static func probeExecutableURL() throws -> URL {
    let executableURL = Bundle(for: ProjectionProbeBundleToken.self).bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("GRDBReadOnlyProjectionProbe")
    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
      throw ProbeLocationError.executableNotFound(executableURL)
    }
    return executableURL
  }

  private static func waitForExit(_ process: Process, timeout: Duration) async throws -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while process.isRunning {
      guard clock.now < deadline else { return false }
      try await Task.sleep(for: .milliseconds(10))
    }
    return true
  }

  private static func terminate(_ process: Process) async {
    guard process.isRunning else { return }
    process.terminate()
    if await (try? waitForExit(process, timeout: .milliseconds(250))) == true { return }
    forceTerminateIfRunning(process)
    _ = try? await waitForExit(process, timeout: .seconds(1))
  }

  private static func forceTerminateIfRunning(_ process: Process) {
    guard process.isRunning else { return }
    kill(process.processIdentifier, SIGKILL)
  }
}

private final class ProjectionProbeBundleToken: NSObject {}

private struct ProjectionProbeResult: Codable {
  let processIdentifier: Int32
  let todos: [Todo]
}

private enum ProbeLocationError: Error {
  case executableNotFound(URL)
}

private enum ProbeExecutionError: Error {
  case timedOut
  case failed(status: Int32, standardError: String)
}
