import Common
import SwiftData
import SwiftUI
import TodoMateData

extension TodoMateApp {
  static func checkAndHandleAppUpdate(container: AppDIContainer) {
    let userDefaults = container.core.userDefaults

    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(for: .appLastVersion)

    Log.info(
      "Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")

    #if DEBUG
      guard Self.isUITesting else { return }
    #endif

    // 업데이트 기록이 존재하면 작업 x -> 3.0.0 이전버전에서 업데이트 시, 수행
    if lastVersion == nil {
      Log.info("First launch detected. Initializing app state...")
      // Public 컨테이너가 있으면 로그아웃 시도 (실질적으로 첫 실행시에는 없을 가능성이 큼)
      try? container.pub.authService.signOut()

      // 앱의 모든 UserDefaults 데이터 삭제
      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
      }
    }

    // 현재 버전 저장
    userDefaults.set(currentVersion, for: .appLastVersion)
  }

  #if DEBUG
    static func parseSenarioFromArguments() -> String {
      var scenario = "group_user" // Default

      Log.debug("Arguments: \(CommandLine.arguments)")

      if let index = CommandLine.arguments.firstIndex(of: "-scenario"),
         index + 1 < CommandLine.arguments.count {
        scenario = CommandLine.arguments[index + 1]
      }

      Log.debug("Selected Scenario: \(scenario)")
      return scenario
    }
  #endif
}

#if DEBUG
  enum MockDataSeeder {
    @MainActor
    static func seed(container: ModelContainer) {
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
