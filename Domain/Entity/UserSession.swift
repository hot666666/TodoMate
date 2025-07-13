//
//  UserSession.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

struct UserSession {
  let currentUser: User
  let groupMembers: [User]

  init(currentUser: User, groupMembers: [User]) {
    self.currentUser = currentUser
    self.groupMembers = groupMembers.placingFirst(currentUser)
  }
}

extension UserSession {
  static let stub = UserSession(
    currentUser: User.stub,
    groupMembers: User.stubs
  )
}
