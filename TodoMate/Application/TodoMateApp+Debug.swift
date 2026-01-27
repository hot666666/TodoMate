//
//  TodoMateApp+Debug.swift
//  TodoMate
//
//  Created by agent on 1/15/26.
//

#if DEBUG
  import Common
  import GRDB
  import SwiftUI
  import TodoMateData
  import TodoMateDomain

  // MARK: - Debug Configuration

  enum DebugConfiguration {
    /// Mock 컨테이너 사용 여부 (스크린샷 테스트용)
    static var isUsingMock: Bool {
      ProcessInfo.processInfo.arguments.contains("-use-mock-container")
    }

    /// 에뮬레이터 사용 여부 (런타임 테스트용)
    static var isUsingEmulator: Bool {
      ProcessInfo.processInfo.arguments.contains("-use-emulator")
    }

    /// Firebase 설정 (에뮬레이터 또는 프로덕션)
    @MainActor
    static func configureFirebase() {
      if isUsingEmulator {
        TodoMateDataConfiguration.configure(mode: .emulator)
      } else {
        TodoMateDataConfiguration.configure()
      }
    }

    /// DI Container 생성 (Mock 또는 실제)
    @MainActor
    static func makeContainer() -> AppDIContainer? {
      guard isUsingMock else { return nil }

      let scenario = parseScenarioFromArguments()
      return AppDIContainer.makeMock(for: scenario)
    }

    /// Launch Argument에서 시나리오 파싱
    private static func parseScenarioFromArguments() -> String {
      Log.debug("Arguments: \(CommandLine.arguments)")

      if let index = CommandLine.arguments.firstIndex(of: "-scenario"),
         index + 1 < CommandLine.arguments.count {
        let scenario = CommandLine.arguments[index + 1]
        Log.debug("Selected Scenario: \(scenario)")
        return scenario
      }

      return "group_user" // Default
    }
  }

  // MARK: - Mock Data Seeder

  enum MockDataSeeder {
    @MainActor
    static func seedIfNeeded(database: GRDBDatabase) {
      guard DebugConfiguration.isUsingMock else { return }

      Task {
        do {
          try await database.dbWriter.write { db in
            if try GRDBTodo.fetchCount(db) > 0 { return }

            let today = Date()
            let calendar = Calendar.current

            let todo1 = GRDBTodo(
              id: UUID().uuidString,
              content: "Buy Groceries",
              statusRawValue: "todo",
              detail: "",
              date: today,
              createdAt: today,
              updatedAt: today,
              owner: "user_1",
              isDeleted: false
            )

            let todo2 = GRDBTodo(
              id: UUID().uuidString,
              content: "Team Meeting",
              statusRawValue: "done",
              detail: "Prepare quarterly report",
              date: today,
              createdAt: today,
              updatedAt: today,
              owner: "user_1",
              isDeleted: false
            )

            let todo3 = GRDBTodo(
              id: UUID().uuidString,
              content: "Walk the dog",
              statusRawValue: "todo",
              detail: "",
              date: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
              createdAt: today,
              updatedAt: today,
              owner: "user_1",
              isDeleted: false
            )

            try todo1.insert(db)
            try todo2.insert(db)
            try todo3.insert(db)

            let memo1 = GRDBMemo(
              id: UUID().uuidString,
              content: "Project Ideas\n\n1. AI Assistant\n2. Smart Home",
              createdAt: today,
              updatedAt: today,
              ownerId: "user_1",
              isDeleted: false
            )

            let memo2 = GRDBMemo(
              id: UUID().uuidString,
              content: "Shopping List\n- Milk\n- Eggs\n- Bread",
              createdAt: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
              updatedAt: today,
              ownerId: "user_1",
              isDeleted: false
            )

            try memo1.insert(db)
            try memo2.insert(db)
          }
          print("✅ Mock data seeded successfully")

        } catch {
          print("❌ Failed to seed mock data: \(error)")
        }
      }
    }
  }

#endif
