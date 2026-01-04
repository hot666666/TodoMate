//
//  GroupFeedViewModel.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import Foundation
import Observation
import SwiftUI

@Observable
class GroupFeedViewModel {
  var activeGroup: Group?
  var members: [User] = []

  // helper dict for quick lookups
  var memberMap: [String: User] = [:]

  // Key: Member ID, Value: [Todo]
  var memberTodos: [String: [Todo]] = [:]

  // Chat
  var chatMessages: [ChatMessage] = []
  var chatInputText: String = ""

  // MOCK DATA GENERATION (Since backend isn't fully ready for realtime yet)
  // In a real app, these would be fetched from Firestore repositories

  init() {
    // Load some mock data for preview/development purposes
    loadMockData()
  }

  func loadMockData() {
    // 1. Setup a mock group
    activeGroup = Group(
      id: "group_1",
      name: "Design Team",
      memberIds: ["user_1", "user_2", "user_3"],
      inviteCode: "DESIGN123",
    )

    // 2. Setup mock members
    let user1 = User(
      id: "user_1", displayName: "Sarah Chen", email: "sarah@example.com",
      avatarUrl: "https://i.pravatar.cc/150?u=sarah", groupId: "group_1",
    )
    let user2 = User(
      id: "user_2", displayName: "Marcus Johnson", email: "marcus@example.com",
      avatarUrl: "https://i.pravatar.cc/150?u=marcus", groupId: "group_1",
    )
    let user3 = User(
      id: "user_3", displayName: "Alex Morgan", email: "alex@example.com",
      avatarUrl: "https://i.pravatar.cc/150?u=alex", groupId: "group_1",
    ) // Assumed "Me"

    members = [user1, user2, user3]
    memberMap = Dictionary(uniqueKeysWithValues: members.map { ($0.id ?? "", $0) })

    // 3. Setup mock todos
    memberTodos["user_1"] = [
      Todo(
        groupId: "group_1", owner: "user_1",
        content: "Finalize moodboard for social campaign", status: .done,
        date: Date().addingTimeInterval(-3600),
      ),
      Todo(
        groupId: "group_1", owner: "user_1", content: "Review copy drafts for landing page",
        status: .todo, tags: ["High"],
      ),
      Todo(
        groupId: "group_1", owner: "user_1",
        content: "Schedule photoshoot with external team", status: .todo,
      ),
    ]

    memberTodos["user_2"] = [
      Todo(
        groupId: "group_1", owner: "user_2", content: "Audit existing component library",
        status: .todo,
      ),
      Todo(
        groupId: "group_1", owner: "user_2", content: "Define new color palette tokens",
        status: .todo, tags: ["System"],
      ),
    ]

    // 4. Setup mock chat messages
    chatMessages = [
      ChatMessage(
        groupId: "group_1", senderId: "user_1",
        text: "Hey team, just uploaded the new assets for Q4. Can you check them out?",
      ),
      ChatMessage(
        groupId: "group_1", senderId: "user_3",
        text: "Looks great! I especially like the color usage here.",
        imageUrl: "https://picsum.photos/400/300",
      ),
    ]
  }

  // Chat Actions
  func sendMessage(text: String?, image: Data?) {
    guard let group = activeGroup else { return }
    // In a real app, use Auth service to get current user ID
    let currentUserId = "user_3"

    let newMessage = ChatMessage(
      groupId: group.id ?? "",
      senderId: currentUserId,
      text: text,
      localImageData: image,
    )

    chatMessages.append(newMessage)
    chatInputText = ""
  }

  func getMember(byId id: String) -> User? {
    memberMap[id]
  }
}
