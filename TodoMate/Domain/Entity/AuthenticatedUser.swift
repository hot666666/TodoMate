//
//  AuthenticatedUser.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

struct AuthenticatedUser: Codable {
  let uid: String
  let gid: String

  static let stub = AuthenticatedUser(uid: User.stub[0].uid, gid: "")
  static let hasGroupStub = AuthenticatedUser(uid: User.stub[0].uid, gid: UserGroup.stub.id)
}

extension AuthenticatedUser {
  static func from(_ user: User) -> AuthenticatedUser {
    AuthenticatedUser(uid: user.uid, gid: user.gid)
  }
}
