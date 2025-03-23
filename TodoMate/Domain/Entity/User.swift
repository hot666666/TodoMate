//
//  User.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import Foundation

struct User: Codable {
  var uid: String
  var nickname: String
  var gid: String?

  init(uid: String = UUID().uuidString, nickname: String, gid: String? = nil) {
    self.uid = uid
    self.nickname = nickname
    self.gid = gid
  }
}

extension User {
  static let stub: [User] = [
    .init(uid: "hs", nickname: "hs", gid: UserGroup.stub.id),
    .init(uid: "jy", nickname: "jy", gid: UserGroup.stub.id),
  ]

  static func from(_ dto: UserDTO) -> User? {
    guard let uid = dto.id else {
      return nil
    }
    return User(uid: uid, nickname: dto.nickname, gid: dto.gid)
  }
}
