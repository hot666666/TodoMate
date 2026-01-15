//
//  GroupFeedViewModel.swift
//  TodoMate
//
//  ViewModel for Group Feed view.
//
//  Created by hs on 1/5/26.
//

import SwiftUI
import TodoMateDomain

@Observable
@MainActor
final class GroupFeedViewModel {
  @ObservationIgnored private let userDefaults: UserDefaults

  var isChatVisible = true {
    didSet {
      userDefaults.set(isChatVisible, for: .chatPanelVisibility)
    }
  }

  var selectedMemberId: String?

  var chatInputText: String = ""

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    isChatVisible = userDefaults.bool(for: .chatPanelVisibility, default: true)
  }

  // MARK: - Actions

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

  func getMember(byId id: String, sessionStore: SessionStore) -> User? {
    sessionStore.groupMembers.first(where: { $0.id == id })
  }
}
