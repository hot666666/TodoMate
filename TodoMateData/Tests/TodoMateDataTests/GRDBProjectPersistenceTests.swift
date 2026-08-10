import Foundation
import Testing
import TodoMateApplication
@testable import TodoMateData
import TodoMateDomain

@Suite("GRDB Project persistence")
struct GRDBProjectPersistenceTests {
  @Test("Project and selected Project survive reopening the database")
  func restoreAfterReopen() async throws {
    let databaseURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("TodoMateProject-\(UUID().uuidString).sqlite")
    defer { try? FileManager.default.removeItem(at: databaseURL) }

    let id = ProjectID(rawValue: "project-1")
    let instant = Date(timeIntervalSince1970: 1_786_363_200)
    do {
      let database = try GRDBDatabase(storage: .file(databaseURL))
      let client = ProjectClient.grdb(
        database: database,
        generateID: { id },
        generateMembershipID: { MembershipID(rawValue: "membership-1") },
        now: { instant },
      )
      _ = try await client.createLocal(.init(name: "Daily"))
      let membership = try await database.writer.read { connection in
        try MembershipRecord.fetchOne(connection, key: "membership-1")
      }
      #expect(membership?.projectId == id.rawValue)
      #expect(membership?.authorId == User.local.id)
      #expect(membership?.role == Membership.Role.owner.rawValue)
    }

    let reopened = try GRDBDatabase(storage: .file(databaseURL))
    let snapshot = try await firstSnapshot(from: ProjectClient.grdb(database: reopened))

    #expect(snapshot.selectedProjectID == id)
    #expect(snapshot.projects.map(\.id) == [id])
    #expect(snapshot.projects.first?.name.value == "Daily")
    #expect(snapshot.projects.first?.lifecycle == .local)
  }

  @Test("Selecting an unknown Project fails without changing selection")
  func rejectUnknownSelection() async throws {
    let database = try GRDBDatabase(storage: .inMemory)
    let knownID = ProjectID(rawValue: "known")
    let client = ProjectClient.grdb(database: database, generateID: { knownID })
    _ = try await client.createLocal(.init(name: "Known"))

    await #expect(throws: GRDBProjectPersistence.Error.missingProject(.init(rawValue: "missing"))) {
      try await client.select(.init(rawValue: "missing"))
    }
    #expect(try await firstSnapshot(from: client).selectedProjectID == knownID)
  }

  private func firstSnapshot(from client: ProjectClient) async throws -> ProjectWorkspaceSnapshot {
    for await snapshot in client.snapshots() {
      return snapshot
    }
    throw SnapshotError.finishedWithoutValue
  }

  private enum SnapshotError: Error {
    case finishedWithoutValue
  }
}
