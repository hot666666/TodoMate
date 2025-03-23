//
//  AuthenticatedUser.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

struct AuthenticatedUser: Codable {
  let uid: String
  var gid: String?

  static let anonymous = AuthenticatedUser(uid: "")
  static let stub = AuthenticatedUser(uid: User.stub[0].uid)
  static let hasGroupStub = AuthenticatedUser(uid: User.stub[0].uid, gid: "gid1")
}

extension AuthenticatedUser {
  static func from(_ user: User) -> AuthenticatedUser {
    AuthenticatedUser(uid: user.uid, gid: user.gid)
  }
}
