//
//  GroupFeedViewModel.swift
//  TodoMate
//
//  ViewModel for Group Feed view.
//
//  Created by agent on 1/5/26.
//

import Observation
import SwiftUI

@Observable
final class GroupFeedViewModel {
  var chatInputText: String = ""
  var layout: GroupFeedLayout = .init()

  // MARK: - Actions

  @MainActor
  func sendMessage(
    text: String, image _: Data?, sessionStore: SessionStore, messageStore: MessageStore,
  ) {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else { return }

    let newMessage = GroupMessage(
      content: trimmedText,
      groupId: sessionStore.userGroupId,
      owner: sessionStore.userId,
    )

    // Note: Image upload is not yet supported by GroupMessage domain entity.
    // We are currently ignoring the image data.

    messageStore.add(newMessage, userId: sessionStore.userId)
    chatInputText = ""
  }

  @MainActor
  func getMember(byId id: String, sessionStore: SessionStore) -> User? {
    sessionStore.userGroup.first(where: { $0.id == id })
  }
}

struct GroupFeedLayout {
  var showSidebar: Bool = true
  var showChat: Bool = true
  var sidebarWidth: CGFloat = 260
  var chatWidth: CGFloat = 320
}
