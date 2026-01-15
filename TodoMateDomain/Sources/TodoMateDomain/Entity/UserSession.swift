//
//  UserSession.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public struct UserSession: Sendable, Equatable {
  public let currentUser: User
  public let groupMembers: [User]

  public init(currentUser: User, groupMembers: [User]) {
    self.currentUser = currentUser
    self.groupMembers = groupMembers.placingFirst(currentUser)
  }
}

public extension UserSession {
  static let stub = UserSession(
    currentUser: User.stub,
    groupMembers: User.stubs,
  )
}
