//
//  ViewUser.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import Foundation

/// Presentation layer model for User
struct ViewUser: Identifiable, Equatable {
  let id: String
  let displayName: String
  let avatarUrl: String?

  init(id: String, displayName: String, avatarUrl: String? = nil) {
    self.id = id
    self.displayName = displayName
    self.avatarUrl = avatarUrl
  }

  init(from user: User) {
    id = user.id
    displayName = user.displayName
    // Domain User doesn't have avatarUrl yet, so we leave it nil or could map from ID if we had a service
    avatarUrl = nil
  }
}
