//
//  HomeScreen.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct HomeScreen: View {
  @Environment(DIContainer.self) var container
  @Environment(SessionStore.self) var sessionStore
  @Environment(MessageStore.self) var messageStore
  @Environment(TodoStore.self) var todoStore
  @Environment(MemoStore.self) var memoStore
  @Environment(OverlayManager.self) var overlayManager
  @Environment(RefreshTrigger.self) var refreshTrigger

  @AppStorage("userSelection.showDropdown") private var showDropdown: Bool = false
  @State private var selectedUserId: String = ""
  @State private var isEditingMemo: Bool = false

  enum Action {
    case setSelectedUser(String)
    case refresh
  }

  @MainActor
  private func perform(_ action: Action) async {
    switch action {
    case let .setSelectedUser(userId):
      selectedUserId = userId

    case .refresh:
      let userIds = sessionStore.userGroup.map(\.id)
      await loadCachedMemoAndTodo(for: userIds)
      await memoStore.load(for: userIds, useCache: false)
      await todoStore.observe(for: userIds)
    }
  }

  private func loadCachedMemoAndTodo(for userIds: [String]) async {
    await memoStore.load(for: userIds)
    await todoStore.load(for: userIds, currentUserId: sessionStore.userId)
  }
}

extension HomeScreen {
  var body: some View {
    VStack {
      VStack(spacing: HomeDesignSystem.Layout.sectionSpacing) {
        UserSelectionHeader(
          selectedUserId: $selectedUserId,
          showDropdown: $showDropdown,
          isEditingMemo: isEditingMemo
        )
        .padding([.horizontal, .top], HomeDesignSystem.Padding.large)
        .shadow(radius: HomeDesignSystem.Shadow.light)

        if showDropdown {
          MemoSection(
            selectedUserId: selectedUserId,
            isEditingMemo: $isEditingMemo
          )
          .padding(.horizontal, HomeDesignSystem.Padding.small)
        }

        TodoListSection(selectedUserId: selectedUserId)
          .background(.ultraThinMaterial, in: .rect(cornerRadius: HomeDesignSystem.CornerRadius.large))
          .shadow(radius: HomeDesignSystem.Shadow.light)
          .padding([.horizontal, .bottom], HomeDesignSystem.Padding.large)
      }
    }
    .task(id: refreshTrigger.value) {
      await perform(.refresh)
    }
    .onAppear {
      Task { await perform(.setSelectedUser(sessionStore.userId)) }
    }
  }
}

#Preview {
  HomeScreen()
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .environment(OverlayManager())
    .environment(RefreshTrigger())
    .frame(width: 500, height: 400)
}
