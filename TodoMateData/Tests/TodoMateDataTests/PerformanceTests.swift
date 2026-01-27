import XCTest
import SwiftData
import GRDB
@testable import TodoMateData
import TodoMateDomain

final class PerformanceTests: XCTestCase {

    // MARK: - SwiftData Setup
    var modelContainer: ModelContainer!
    var swiftDataRepository: SwiftDataTodoRepositoryImpl!

    // MARK: - GRDB Setup
    var dbQueue: DatabaseQueue!
    var grdbRepository: GRDBTodoRepositoryImpl!

    override func setUp() async throws {
        // SwiftData Setup
        let schema = Schema([SDTodo.self, SDMemo.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        swiftDataRepository = SwiftDataTodoRepositoryImpl(modelContainer: modelContainer)

        // GRDB Setup
        dbQueue = try DatabaseQueue()
        // Migration (Copied from GRDBDatabase.swift)
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "todo") { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("statusRawValue", .text).notNull()
                t.column("detail", .text).notNull()
                t.column("date", .datetime).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("owner", .text).notNull()
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
            }
             try db.create(table: "memo") { t in
                t.column("id", .text).primaryKey()
                t.column("content", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("ownerId", .text).notNull()
                t.column("isDeleted", .boolean).notNull().defaults(to: false)
              }
        }
        try migrator.migrate(dbQueue)
        grdbRepository = GRDBTodoRepositoryImpl(dbWriter: dbQueue)
    }

    override func tearDown() {
        modelContainer = nil
        swiftDataRepository = nil
        dbQueue = nil
        grdbRepository = nil
    }

    func testPerformanceComparison() async throws {
        print("\n=== Performance Benchmark: SwiftData vs GRDB (1,000 items) ===")

        // --- SwiftData ---
        print("\n[SwiftData]")
        let sdCreateStart = Date()
        for i in 0..<1000 {
            let todo = Todo(
                id: UUID().uuidString,
                content: "Todo \(i)",
                status: .todo,
                detail: "Detail for todo \(i)",
                date: Date(),
                createdAt: Date(),
                updatedAt: Date(),
                owner: "user1",
                isDeleted: false
            )
            try await swiftDataRepository.create(todo)
        }
        let sdCreateDuration = Date().timeIntervalSince(sdCreateStart)
        print("Create: \(String(format: "%.4f", sdCreateDuration))s")

        let sdReadStart = Date()
        let sdTodos = try await swiftDataRepository.readAll(query: TodoQuery(filters: []), useCache: false)
        let sdReadDuration = Date().timeIntervalSince(sdReadStart)
        print("Read:   \(String(format: "%.4f", sdReadDuration))s (Count: \(sdTodos.count))")

        let sdUpdateStart = Date()
        for i in 0..<100 {
            if var todo = sdTodos[safe: i] {
                todo.status = .done
                try await swiftDataRepository.update(todo)
            }
        }
        let sdUpdateDuration = Date().timeIntervalSince(sdUpdateStart)
        print("Update: \(String(format: "%.4f", sdUpdateDuration))s (100 items)")

        let sdDeleteStart = Date()
        for i in 0..<100 {
            if let todo = sdTodos[safe: i] {
                try await swiftDataRepository.delete(todo.id)
            }
        }
        let sdDeleteDuration = Date().timeIntervalSince(sdDeleteStart)
        print("Delete: \(String(format: "%.4f", sdDeleteDuration))s (100 items)")


        // --- GRDB ---
        print("\n[GRDB]")
        let grdbCreateStart = Date()
        for i in 0..<1000 {
            let todo = Todo(
                id: UUID().uuidString,
                content: "Todo \(i)",
                status: .todo,
                detail: "Detail for todo \(i)",
                date: Date(),
                createdAt: Date(),
                updatedAt: Date(),
                owner: "user1",
                isDeleted: false
            )
            try await grdbRepository.create(todo)
        }
        let grdbCreateDuration = Date().timeIntervalSince(grdbCreateStart)
        print("Create: \(String(format: "%.4f", grdbCreateDuration))s")

        let grdbReadStart = Date()
        let grdbTodos = try await grdbRepository.readAll(query: TodoQuery(filters: []), useCache: false)
        let grdbReadDuration = Date().timeIntervalSince(grdbReadStart)
        print("Read:   \(String(format: "%.4f", grdbReadDuration))s (Count: \(grdbTodos.count))")

        let grdbUpdateStart = Date()
        for i in 0..<100 {
            if var todo = grdbTodos[safe: i] {
                todo.status = .done
                try await grdbRepository.update(todo)
            }
        }
        let grdbUpdateDuration = Date().timeIntervalSince(grdbUpdateStart)
        print("Update: \(String(format: "%.4f", grdbUpdateDuration))s (100 items)")

        let grdbDeleteStart = Date()
        for i in 0..<100 {
            if let todo = grdbTodos[safe: i] {
                try await grdbRepository.delete(todo.id)
            }
        }
        let grdbDeleteDuration = Date().timeIntervalSince(grdbDeleteStart)
        print("Delete: \(String(format: "%.4f", grdbDeleteDuration))s (100 items)")

        print("\n============================================================\n")
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
