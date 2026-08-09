//
//  TodoMateApp+Debug.swift
//  TodoMate
//
//  Created by agent on 1/15/26.
//

#if DEBUG
  import Common
  import SwiftData
  import SwiftUI
  import TodoMateData
  import TodoMateDomain

  // MARK: - Debug Configuration

  enum DebugConfiguration {
    /// Mock 컨테이너 사용 여부 (스크린샷 테스트용)
    static var isUsingMock: Bool {
      ProcessInfo.processInfo.arguments.contains("-use-mock-container")
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
    static func seedIfNeeded(container: ModelContainer) {
      guard DebugConfiguration.isUsingMock else { return }

      let context = container.mainContext
      let todoDescriptor = FetchDescriptor<SDTodo>()

      do {
        if try context.fetchCount(todoDescriptor) > 0 { return }

        let today = Date()
        let calendar = Calendar.current

        let todo1 = SDTodo(
          content: "Buy Groceries",
          status: "todo",
          detail: "",
          date: today,
          createdAt: today,
          updatedAt: today,
          owner: "user_1",
        )

        let todo2 = SDTodo(
          content: "Team Meeting",
          status: "done",
          detail: "Prepare quarterly report",
          date: today,
          createdAt: today,
          updatedAt: today,
          owner: "user_1",
        )

        let todo3 = SDTodo(
          content: "Walk the dog",
          status: "todo",
          detail: "",
          date: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
          createdAt: today,
          updatedAt: today,
          owner: "user_1",
        )

        context.insert(todo1)
        context.insert(todo2)
        context.insert(todo3)

        let memo1 = SDMemo(
          content: "Project Ideas\n\n1. AI Assistant\n2. Smart Home",
          createdAt: today,
          updatedAt: today,
          ownerId: "user_1",
        )

        let memo2 = SDMemo(
          content: "Shopping List\n- Milk\n- Eggs\n- Bread",
          createdAt: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
          updatedAt: today,
          ownerId: "user_1",
        )

        context.insert(memo1)
        context.insert(memo2)

        try context.save()
        print("✅ Mock data seeded successfully")

      } catch {
        print("❌ Failed to seed mock data: \(error)")
      }
    }
  }

#endif
