//
//  UserDefaultsKey.swift
//  TodoMate
//
//  Created by agent on 1/6/26.
//

import Foundation

/// UserDefaults 키를 중앙에서 관리하는 enum
enum UserDefaultsKey: String {
  // MARK: - App Migration

  /// 앱 버전 (업데이트 감지용)
  case appLastVersion = "app_last_version"

  // MARK: - Network

  /// 네트워크 모드 (온라인/오프라인)
  case networkModeIsOnline = "network_mode_is_online"

  // MARK: - UI Preference

  /// 사이드바 표시 상태
  case sidebarVisibility = "sidebar_visibility"
}

// MARK: - UserDefaults Extension

extension UserDefaults {
  /// In-memory UserDefaults for previews/tests
  static var preview: UserDefaults {
    let suiteName = "preview"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  func set(_ value: Any?, for key: UserDefaultsKey) {
    set(value, forKey: key.rawValue)
  }

  func string(for key: UserDefaultsKey) -> String? {
    string(forKey: key.rawValue)
  }

  func bool(for key: UserDefaultsKey, default defaultValue: Bool = false) -> Bool {
    object(forKey: key.rawValue) as? Bool ?? defaultValue
  }

  func data(for key: UserDefaultsKey) -> Data? {
    data(forKey: key.rawValue)
  }
}
