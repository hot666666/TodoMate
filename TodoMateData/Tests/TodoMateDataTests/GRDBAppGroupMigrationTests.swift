import Common
import Foundation
import GRDB
import Testing
import TodoMateDomain

@testable import TodoMateData

@Suite("GRDB App Group Migration Tests", .serialized)
struct GRDBAppGroupMigrationTests {
  @Test("Debug container resolution requests only the registered shared App Group")
  func debugContainerResolutionUsesRegisteredAppGroupOnly() throws {
    #if DEBUG
      var requestedIdentifiers: [String] = []
      let debugGroupURL = URL(fileURLWithPath: "/tmp/debug-group", isDirectory: true)

      let resolution = GRDBAppGroupStorage.containerResolution { identifier in
        requestedIdentifiers.append(identifier)
        return debugGroupURL
      }

      #expect(
        AppEnvironment.Container.storageAppGroupIdentifier
          == AppEnvironment.Container.appGroupIdentifier,
      )
      #expect(requestedIdentifiers == [AppEnvironment.Container.storageAppGroupIdentifier])
      #expect(resolution.groupURL == debugGroupURL)
      #expect(resolution.legacyGroupURL == debugGroupURL)
    #endif
  }

  @Test("Legacy-enabled container resolution requests both App Groups")
  func legacyEnabledContainerResolutionRequestsBothAppGroups() {
    var requestedIdentifiers: [String] = []
    let canonicalURL = URL(fileURLWithPath: "/tmp/canonical-group", isDirectory: true)
    let legacyURL = URL(fileURLWithPath: "/tmp/legacy-group", isDirectory: true)

    let resolution = GRDBAppGroupStorage.containerResolution(
      primaryAppGroupIdentifier: AppEnvironment.Container.appGroupIdentifier,
      migrationSourceAppGroupIdentifier: AppEnvironment.Container.legacyAppGroupIdentifier,
    ) { identifier in
      requestedIdentifiers.append(identifier)
      switch identifier {
      case AppEnvironment.Container.appGroupIdentifier:
        return canonicalURL
      case AppEnvironment.Container.legacyAppGroupIdentifier:
        return legacyURL
      default:
        return nil
      }
    }

    #expect(
      requestedIdentifiers == [
        AppEnvironment.Container.appGroupIdentifier,
        AppEnvironment.Container.legacyAppGroupIdentifier,
      ],
    )
    #expect(resolution.groupURL == canonicalURL)
    #expect(resolution.legacyGroupURL == legacyURL)
  }

  @Test("Shared locations include legacy SwiftData candidates from both groups")
  func includesLegacySwiftDataCandidates() throws {
    let registeredGroupURL = URL(fileURLWithPath: "/tmp/registered-group", isDirectory: true)
    let legacyGroupURL = URL(fileURLWithPath: "/tmp/legacy-group", isDirectory: true)
    let locations = GRDBAppGroupStorage.locations(
      groupURL: registeredGroupURL,
      legacyGroupURL: legacyGroupURL,
    )
    let legacyDatabaseURL = locations.legacyDatabaseURL

    #expect(locations.databaseURL == GRDBAppGroupStorage.databaseURL(in: registeredGroupURL))
    #expect(legacyDatabaseURL == GRDBAppGroupStorage.databaseURL(in: legacyGroupURL))
    #expect(
      locations.legacyStoreURLs.contains(
        legacyDatabaseURL
          .deletingLastPathComponent()
          .deletingLastPathComponent()
          .appendingPathComponent(
            "\(legacyDatabaseURL.deletingLastPathComponent().lastPathComponent).store",
          ),
      ),
    )
    #expect(
      locations.legacyStoreURLs.contains(
        legacyGroupURL.appendingPathComponent("default.store"),
      ),
    )
  }

  @Test("Transition fails closed when the legacy group container cannot be resolved")
  func requiresLegacyGroupContainerAccess() {
    let resolution = GRDBAppGroupContainerResolution(
      groupURL: URL(fileURLWithPath: "/tmp/registered-group", isDirectory: true),
      legacyGroupURL: nil,
    )

    do {
      _ = try GRDBAppGroupStorage.locations(resolution: resolution)
      Issue.record("Expected the missing legacy App Group to fail closed")
    } catch let error as LocalDatabaseError {
      guard case .appGroupContainerUnavailable(let identifier) = error else {
        Issue.record("Expected appGroupContainerUnavailable, got \(error)")
        return
      }
      #expect(identifier.hasPrefix("8PRWAG4355.io.hotcs6.TodoMate"))
    } catch {
      Issue.record("Expected LocalDatabaseError, got \(error)")
    }
    #expect(GRDBAppGroupStorage.readOnlyLocations(resolution: resolution) == nil)
  }

  @Test("Migrates a live WAL snapshot and preserves the legacy database")
  func migratesLiveWALSnapshot() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let fixture = Fixture()
    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await fixture.insert(into: legacyDatabase)

    let walAttributes = try FileManager.default.attributesOfItem(
      atPath: layout.legacyDatabaseURL.path + "-wal",
    )
    #expect((walAttributes[.size] as? NSNumber)?.intValue ?? 0 > 0)

    let outcome = try GRDBAppGroupMigration.migrateIfNeeded(
      from: layout.legacyDatabaseURL,
      to: layout.databaseURL,
    )
    #expect(outcome == .migrated)

    guard let migratedDatabase = try GRDBReadOnlyDatabase(storage: .file(layout.databaseURL)) else {
      Issue.record("Expected a current migrated database")
      return
    }
    let migratedTodo = try await GRDBTodoReader(database: migratedDatabase).fetch(
      query: TodoQuery().owner(userId: fixture.ownerID),
    )
    #expect(migratedTodo == [fixture.todo])
    let migratedMemo = try await migratedDatabase.reader.read { databaseConnection in
      try MemoRecord.fetchOne(databaseConnection, key: fixture.memo.id)?.domainValue()
    }
    #expect(migratedMemo == fixture.memo)
    await assertReadOnly(database: migratedDatabase, todoID: fixture.todo.id)

    let legacyTodo = try await GRDBTodoRepository(database: legacyDatabase).read(
      id: fixture.todo.id)
    let legacyMemo = try await GRDBMemoRepository(database: legacyDatabase).read(
      id: fixture.memo.id)
    #expect(legacyTodo == fixture.todo)
    #expect(legacyMemo == fixture.memo)
    let legacyHasMarker = try await legacyDatabase.writer.read { databaseConnection in
      try String.fetchOne(
        databaseConnection,
        sql: "SELECT value FROM localMetadata WHERE key = ?",
        arguments: ["appGroupContainerMigration.v1"],
      ) != nil
    }
    #expect(!legacyHasMarker)
  }

  @Test("A valid marker makes migration idempotent without rewriting the destination")
  func isIdempotent() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await Fixture().insert(into: legacyDatabase)
    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .migrated,
    )
    let firstDatabaseBytes = try Data(contentsOf: layout.databaseURL)

    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .alreadyMigrated,
    )
    #expect(try Data(contentsOf: layout.databaseURL) == firstDatabaseBytes)
  }

  @Test("Concurrent migrations in one process serialize to one promotion")
  func serializesConcurrentSameProcessMigrations() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let fixture = Fixture()
    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await fixture.insert(into: legacyDatabase)
    let legacyDatabaseURL = layout.legacyDatabaseURL
    let databaseURL = layout.databaseURL
    let participantCount = 8
    let startGate = AsyncStartGate(participantCount: participantCount)

    let outcomes = try await withThrowingTaskGroup(
      of: GRDBAppGroupMigrationOutcome.self,
      returning: [GRDBAppGroupMigrationOutcome].self,
    ) { group in
      for _ in 0..<participantCount {
        group.addTask {
          await startGate.wait()
          return try GRDBAppGroupMigration.migrateIfNeeded(
            from: legacyDatabaseURL,
            to: databaseURL,
          )
        }
      }
      var outcomes: [GRDBAppGroupMigrationOutcome] = []
      for try await outcome in group {
        outcomes.append(outcome)
      }
      return outcomes
    }

    #expect(outcomes.count(where: { $0 == .migrated }) == 1)
    #expect(outcomes.count(where: { $0 == .alreadyMigrated }) == participantCount - 1)
    guard let migratedDatabase = try GRDBReadOnlyDatabase(storage: .file(databaseURL)) else {
      Issue.record("Expected one exact migrated destination")
      return
    }
    #expect(
      try await GRDBTodoReader(database: migratedDatabase).fetch(
        query: TodoQuery().owner(userId: fixture.ownerID),
      ) == [fixture.todo],
    )
    #expect(
      try await GRDBTodoRepository(database: legacyDatabase).read(id: fixture.todo.id)
        == fixture.todo,
    )
  }

  @Test("Destination writes remain valid but legacy drift fails closed")
  func detectsLegacySourceDriftAfterMigration() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let fixture = Fixture()
    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await fixture.insert(into: legacyDatabase)
    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .migrated,
    )

    let destinationTodo = Todo(
      id: "destination-after-migration",
      content: "Canonical destination mutation",
      date: fixture.timestamp,
      createdAt: fixture.timestamp,
      updatedAt: fixture.timestamp,
      owner: fixture.ownerID,
    )
    let destinationDatabase = try GRDBDatabase(storage: .file(layout.databaseURL))
    try await GRDBTodoRepository(database: destinationDatabase).create(destinationTodo)
    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .alreadyMigrated,
    )

    let driftedLegacyTodo = Todo(
      id: "legacy-after-migration",
      content: "Must not be silently ignored",
      date: fixture.timestamp,
      createdAt: fixture.timestamp,
      updatedAt: fixture.timestamp,
      owner: fixture.ownerID,
    )
    try await GRDBTodoRepository(database: legacyDatabase).create(driftedLegacyTodo)

    do {
      _ = try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      )
      Issue.record("Expected legacy source drift to fail closed")
    } catch let error as GRDBAppGroupMigrationError {
      #expect(error == .legacySourceChangedAfterMigration(layout.legacyDatabaseURL))
    }
    #expect(
      GRDBAppGroupMigration.preferredReadOnlyDatabaseURL(
        databaseURL: layout.databaseURL,
        legacyDatabaseURL: layout.legacyDatabaseURL,
      ) == nil,
    )
    #expect(
      try await GRDBTodoRepository(database: destinationDatabase).read(id: destinationTodo.id)
        == destinationTodo,
    )
    #expect(
      try await GRDBTodoRepository(database: destinationDatabase).read(id: driftedLegacyTodo.id)
        == nil,
    )
  }

  @Test("Migration removes only owned orphan staging files while holding its lock")
  func removesOwnedOrphanStagingFiles() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await Fixture().insert(into: legacyDatabase)
    let directoryURL = layout.databaseURL.deletingLastPathComponent()
    let ownedBaseName =
      ".TodoMate.sqlite.app-group-migration-"
      + "11111111-2222-3333-4444-555555555555.tmp"
    let ownedURLs = ["", "-wal", "-shm", "-journal"].map {
      directoryURL.appendingPathComponent(ownedBaseName + $0)
    }
    for url in ownedURLs {
      try Data("orphan".utf8).write(to: url)
    }
    let unownedURL = directoryURL.appendingPathComponent(
      ".TodoMate.sqlite.app-group-migration-not-a-uuid.tmp",
    )
    try Data("preserve".utf8).write(to: unownedURL)
    let ownedNameDirectoryURL = directoryURL.appendingPathComponent(
      ".TodoMate.sqlite.app-group-migration-"
        + "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE.tmp",
      isDirectory: true,
    )
    try FileManager.default.createDirectory(
      at: ownedNameDirectoryURL, withIntermediateDirectories: true)

    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .migrated,
    )

    for url in ownedURLs {
      #expect(!FileManager.default.fileExists(atPath: url.path))
    }
    #expect(FileManager.default.fileExists(atPath: unownedURL.path))
    #expect(FileManager.default.fileExists(atPath: ownedNameDirectoryURL.path))
  }

  @Test("An unmarked destination is preserved and migration fails closed")
  func preservesUnmarkedDestination() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let fixture = Fixture()
    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await fixture.insert(into: legacyDatabase)

    let destinationTodo = Todo(
      id: "destination-only",
      content: "Do not replace",
      date: fixture.timestamp,
      createdAt: fixture.timestamp,
      updatedAt: fixture.timestamp,
      owner: fixture.ownerID,
    )
    let destinationDatabase = try GRDBDatabase(storage: .file(layout.databaseURL))
    try await GRDBTodoRepository(database: destinationDatabase).create(destinationTodo)

    do {
      _ = try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      )
      Issue.record("Expected an untrusted-destination error")
    } catch let error as GRDBAppGroupMigrationError {
      #expect(error == .destinationExistsWithoutValidMarker(layout.databaseURL))
    }

    #expect(
      try await GRDBTodoRepository(database: destinationDatabase).read(id: destinationTodo.id)
        == destinationTodo,
    )
    #expect(
      try await GRDBTodoRepository(database: destinationDatabase).read(id: fixture.todo.id) == nil,
    )
  }

  @Test("Widget selection falls back without writing and prefers a marked new database")
  func selectsReadOnlyDatabaseForWidget() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let fixture = Fixture()
    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await fixture.insert(into: legacyDatabase)

    #expect(
      GRDBAppGroupMigration.preferredReadOnlyDatabaseURL(
        databaseURL: layout.databaseURL,
        legacyDatabaseURL: layout.legacyDatabaseURL,
      ) == layout.legacyDatabaseURL,
    )
    #expect(!FileManager.default.fileExists(atPath: layout.databaseURL.path))

    do {
      let unmarkedDatabase = try GRDBDatabase(storage: .file(layout.databaseURL))
      try await GRDBTodoRepository(database: unmarkedDatabase).create(
        Todo(owner: fixture.ownerID, content: "Untrusted"),
      )
    }
    #expect(
      GRDBAppGroupMigration.preferredReadOnlyDatabaseURL(
        databaseURL: layout.databaseURL,
        legacyDatabaseURL: layout.legacyDatabaseURL,
      ) == layout.legacyDatabaseURL,
    )

    layout.removeDatabase(at: layout.databaseURL)
    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .migrated,
    )
    #expect(
      GRDBAppGroupMigration.preferredReadOnlyDatabaseURL(
        databaseURL: layout.databaseURL,
        legacyDatabaseURL: layout.legacyDatabaseURL,
      ) == layout.databaseURL,
    )

    guard let database = try GRDBReadOnlyDatabase(storage: .file(layout.databaseURL)) else {
      Issue.record("Expected the selected database to open read-only")
      return
    }
    await assertReadOnly(database: database, todoID: fixture.todo.id)
  }

  @Test("Canonical-only Widget selection accepts normal writes after migration")
  func selectsCanonicalOnlyDatabaseAfterNormalWrite() async throws {
    let layout = try TestLayout()
    defer { layout.remove() }

    let fixture = Fixture()
    let legacyDatabase = try GRDBDatabase(storage: .file(layout.legacyDatabaseURL))
    try await fixture.insert(into: legacyDatabase)
    #expect(
      try GRDBAppGroupMigration.migrateIfNeeded(
        from: layout.legacyDatabaseURL,
        to: layout.databaseURL,
      ) == .migrated,
    )

    let canonicalDatabase = try GRDBDatabase(storage: .file(layout.databaseURL))
    let canonicalTodo = Todo(
      id: "canonical-only-write",
      content: "Normal app mutation after migration",
      date: fixture.timestamp,
      createdAt: fixture.timestamp,
      updatedAt: fixture.timestamp,
      owner: fixture.ownerID,
    )
    try await GRDBTodoRepository(database: canonicalDatabase).create(canonicalTodo)

    #expect(
      GRDBAppGroupMigration.preferredReadOnlyDatabaseURL(
        databaseURL: layout.databaseURL,
        legacyDatabaseURL: layout.databaseURL,
      ) == layout.databaseURL,
    )
  }

  private func assertReadOnly(database: GRDBReadOnlyDatabase, todoID: String) async {
    do {
      try await database.reader.read { databaseConnection in
        try databaseConnection.execute(
          sql: "DELETE FROM todo WHERE id = ?",
          arguments: [todoID],
        )
      }
      Issue.record("Expected SQLITE_READONLY")
    } catch let error as DatabaseError {
      #expect(error.resultCode == .SQLITE_READONLY)
    } catch {
      Issue.record("Expected SQLITE_READONLY, got \(error)")
    }
  }
}

private actor AsyncStartGate {
  private let participantCount: Int
  private var continuations: [CheckedContinuation<Void, Never>] = []

  init(participantCount: Int) {
    self.participantCount = participantCount
  }

  func wait() async {
    await withCheckedContinuation { continuation in
      continuations.append(continuation)
      guard continuations.count == participantCount else { return }
      let waitingContinuations = continuations
      continuations.removeAll(keepingCapacity: false)
      for waitingContinuation in waitingContinuations {
        waitingContinuation.resume()
      }
    }
  }
}

private struct Fixture {
  let ownerID = "app-group-owner"
  let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

  var todo: Todo {
    Todo(
      id: "wal-todo",
      content: "Persisted in WAL",
      status: .inProgress,
      detail: "Must survive online backup",
      date: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
      owner: ownerID,
    )
  }

  var memo: Memo {
    Memo(
      id: "wal-memo",
      content: "Memo projection",
      createdAt: timestamp,
      updatedAt: timestamp,
      owner: ownerID,
    )
  }

  func insert(into database: GRDBDatabase) async throws {
    try await GRDBTodoRepository(database: database).create(todo)
    try await GRDBMemoRepository(database: database).create(memo)
  }
}

private struct TestLayout {
  let rootURL: URL
  let legacyDatabaseURL: URL
  let databaseURL: URL

  init() throws {
    rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("app-group-migration-\(UUID().uuidString)", isDirectory: true)
    legacyDatabaseURL =
      rootURL
      .appendingPathComponent("legacy", isDirectory: true)
      .appendingPathComponent("TodoMate.sqlite")
    databaseURL =
      rootURL
      .appendingPathComponent("registered", isDirectory: true)
      .appendingPathComponent("TodoMate.sqlite")
    try FileManager.default.createDirectory(
      at: legacyDatabaseURL.deletingLastPathComponent(),
      withIntermediateDirectories: true,
    )
    try FileManager.default.createDirectory(
      at: databaseURL.deletingLastPathComponent(),
      withIntermediateDirectories: true,
    )
  }

  func removeDatabase(at url: URL) {
    for path in [url.path, url.path + "-wal", url.path + "-shm", url.path + "-journal"]
    where FileManager.default.fileExists(atPath: path) {
      try? FileManager.default.removeItem(atPath: path)
    }
  }

  func remove() {
    try? FileManager.default.removeItem(at: rootURL)
  }
}
