//
//  GroupFeedViewModel.swift
//  TodoMate
//
//  ViewModel for Group Feed view.
//
//  Created by agent on 1/5/26.
//

import SwiftUI

/// Mock Group model for display
struct ViewGroup: Identifiable {
  let id: String
  var name: String
  var memberIds: [String]

  static let mock = ViewGroup(
    id: "design-team",
    name: "Design Team",
    memberIds: ["user_1", "user_2", "user_3"],
  )
}

/// Mock User for display with avatar
struct ViewUser: Identifiable {
  let id: String?
  var displayName: String
  var avatarUrl: String?

  init(id: String?, displayName: String, avatarUrl: String? = nil) {
    self.id = id
    self.displayName = displayName
    self.avatarUrl = avatarUrl
  }

  init(from user: User) {
    id = user.id
    displayName = user.displayName
    avatarUrl = nil // Current domain model doesn't have avatarUrl
  }
}

// MARK: - Mock Data

extension ViewUser {
  static let mockMembers: [ViewUser] = [
    ViewUser(
      id: "user_1",
      displayName: "Sarah Chen",
      avatarUrl: "https://i.pravatar.cc/150?u=sarah",
    ),
    ViewUser(
      id: "user_2",
      displayName: "Mike Johnson",
      avatarUrl: "https://i.pravatar.cc/150?u=mike",
    ),
    ViewUser(
      id: "user_3",
      displayName: "Alex Morgan",
      avatarUrl: "https://i.pravatar.cc/150?u=alex",
    ),
  ]
}

// MARK: - Group Feed ViewModel

@Observable
@MainActor
final class GroupFeedViewModel {
  // State
  var activeGroup: ViewGroup? = ViewGroup.mock
  var members: [ViewUser] = ViewUser.mockMembers
  var memberTodos: [String: [ViewTodo]] = [:]
  var chatMessages: [ChatMessage] = ChatMessage.mockMessages
  var chatInputText: String = ""

  init() {
    // Setup mock data
    memberTodos = [
      "user_1": [
        ViewTodo(
          id: "t1", owner: "user_1", content: "Review design specs",
          status: .inProgress, tags: ["High"],
        ),
        ViewTodo(
          id: "t2", owner: "user_1", content: "Update component library",
          status: .todo, tags: ["System"],
        ),
      ],
      "user_2": [
        ViewTodo(
          id: "t3", owner: "user_2", content: "Fix navigation bug",
          status: .done, tags: ["Bug"],
        ),
      ],
      "user_3": [],
    ]
  }

  func getMember(byId id: String) -> ViewUser? {
    members.first { $0.id == id }
  }

  func sendMessage(text: String, image: Data?) {
    guard !text.isEmpty || image != nil else { return }

    let message = ChatMessage(
      senderId: "user_3", // Current user
      text: text.isEmpty ? nil : text,
      localImageData: image,
    )
    chatMessages.append(message)
    chatInputText = ""
  }
}
