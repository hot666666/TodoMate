//
//  UserDefaults+.swift
//  TodoMate
//
//  Created by agent on 1/6/26.
//

import Foundation

// MARK: - UserDefaults Extension

public extension UserDefaults {
  /// In-memory UserDefaults for preivews/tests
  @MainActor static let preview: UserDefaults = {
    let suiteName = "preview"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }()

  func set(_ value: Any?, for key: UserDefaultsKey) {
    set(value, forKey: key.rawValue)
  }

  func string(for key: UserDefaultsKey) -> String? {
    string(forKey: key.rawValue)
  }

  func bool(for key: UserDefaultsKey, default defaultValue: Bool = false) -> Bool {
    object(forKey: key.rawValue) as? Bool ?? defaultValue
  }

  func double(for key: UserDefaultsKey) -> Double {
    double(forKey: key.rawValue)
  }

  func data(for key: UserDefaultsKey) -> Data? {
    data(forKey: key.rawValue)
  }

  func removeObject(for key: UserDefaultsKey) {
    removeObject(forKey: key.rawValue)
  }
}

// MARK: - UserDefaults Keys

public enum UserDefaultsKey: String {
  // MARK: - App Migration

  /// 앱 버전 (업데이트 감지용)
  case appLastVersion = "app_last_version"

  // MARK: - Network

  /// 네트워크 모드 (온라인/오프라인)
  case networkModeIsOnline = "network_mode_is_online"

  // MARK: - UI Preference

  /// 사이드바 표시 상태
  case sidebarVisibility = "sidebar_visibility"

  /// 채팅 패널 표시 상태
  case chatPanelVisibility = "chat_panel_visibility"

  /// Dock 아이콘 표시 여부
  case showInDock = "show_in_dock"

  /// 창 닫을 때 앱 종료 여부
  case quitOnWindowClose = "quit_on_window_close"

  /// Public 기능 활성화 여부
  case isPublicModeEnabled = "is_public_mode_enabled"

  // MARK: - Sidebar Cache

  /// 캐시된 프로필 이름
  case cachedProfileName = "cached_profile_name"

  /// 캐시된 그룹 이름
  case cachedGroupName = "cached_group_name"

  /// 캐시된 그룹 ID (그룹 존재 여부 판단용)
  case cachedUserGroupId = "cached_user_group_id"

  // MARK: - Message

  /// 마지막 읽은 메시지 타임스탬프
  case lastMessageReadTimestamp = "last_message_read_timestamp"
}
