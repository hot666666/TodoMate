//
//  TodoMateApp+Debug.swift
//  TodoMate
//
//  Created by agent on 1/15/26.
//

#if DEBUG
  import Common
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
    static func seedIfNeeded(container: CoreDIContainer) async {
      guard DebugConfiguration.isUsingMock else { return }

      do {
        let existingCount = try await container.localTodoRepository.fetchCount(query: TodoQuery())
        if existingCount > 0 { return }

        let today = Date()
        for todo in todos(for: today) {
          try await container.localTodoRepository.create(todo)
        }
        for memo in memos(for: today) {
          try await container.localMemoRepository.create(memo)
        }
        Log.info("Mock data seeded successfully", category: .data)
      } catch {
        Log.error("Failed to seed mock data: \(error)", category: .data)
      }
    }

    private static func todos(for today: Date) -> [Todo] {
      let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
      return [
        Todo(
          content: "Buy Groceries", date: today, createdAt: today, updatedAt: today,
          owner: "user_1",
        ),
        Todo(
          content: "Team Meeting", status: .complete, detail: "Prepare quarterly report",
          date: today, createdAt: today, updatedAt: today, owner: "user_1",
        ),
        Todo(
          content: "Walk the dog", date: tomorrow, createdAt: today, updatedAt: today,
          owner: "user_1",
        ),
      ]
    }

    private static func memos(for today: Date) -> [Memo] {
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
      return [
        Memo(
          content: "Project Ideas\n\n1. AI Assistant\n2. Smart Home",
          createdAt: today, updatedAt: today, owner: "user_1",
        ),
        Memo(
          content: "Shopping List\n- Milk\n- Eggs\n- Bread",
          createdAt: yesterday, updatedAt: today, owner: "user_1",
        ),
      ]
    }
  }

#endif
