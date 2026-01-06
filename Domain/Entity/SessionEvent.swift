//
//  SessionEvent.swift
//  TodoMate
//
//  Created by hs on 1/5/26.
//

/// SessionStore가 방출하는 세션 관련 이벤트
enum SessionEvent: Sendable {
  /// 로그인 완료 - 필요한 사용자 정보와 그룹 정보 포함
  /// - userId: 현재 로그인한 사용자 ID
  /// - groupId: 그룹 채팅방 ID
  /// - memberIds: 그룹 멤버들의 사용자 ID 목록
  case loggedIn(userId: String, groupId: String, memberIds: [String])
  /// 로그아웃
  case loggedOut
}
