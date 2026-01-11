import SwiftUI

extension TodoMateApp {
  static func checkAndHandleAppUpdate(container: AppDIContainer) {
    let userDefaults = container.core.userDefaults

    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(for: .appLastVersion)

    Log.info(
      "Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")

    // 업데이트 기록이 존재하면 작업 x -> 3.0.0 이전버전에서 업데이트 시, 수행
    if lastVersion == nil {
      Log.info("First launch detected. Initializing app state...")
      // Public 컨테이너가 있으면 로그아웃 시도 (실질적으로 첫 실행시에는 없을 가능성이 큼)
      try? container.publicContainer?.authService.signOut()

      // 앱의 모든 UserDefaults 데이터 삭제
      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
      }
    }

    // 현재 버전 저장
    userDefaults.set(currentVersion, for: .appLastVersion)
  }

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
}
