//
//  UserDefaultsKey.swift
//  Common
//
//  Created by agent on 1/14/26.
//

/// UserDefaults 키를 중앙에서 관리하는 enum
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
