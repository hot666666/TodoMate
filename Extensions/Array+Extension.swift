//
//  Array+Extension.swift
//  Todo
//
//  Created by hs on 7/1/25.
//

extension [User] {
  func placingFirst(_ user: User) -> [User] {
    [user] + filter { $0.id != user.id }
  }
}
