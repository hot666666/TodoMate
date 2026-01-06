import SwiftUI

extension TodoMateApp {
  static func checkAndHandleAppUpdate(container: DIContainer) {
    let userDefaults = UserDefaults.standard

    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(for: .appLastVersion)

    print(
      "[TodoMateApp] - Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")

    // 업데이트 기록이 존재하면 작업 x -> 3.0.0 이전버전에서 업데이트 시, 수행
    if lastVersion == nil {
      print("[TodoMateApp] - First launch detected. Initializing app state...")
      try? container.authService.signOut()

      // 앱의 모든 UserDefaults 데이터 삭제
      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
      }
    }

    // 현재 버전 저장
    userDefaults.set(currentVersion, for: .appLastVersion)
  }
}
