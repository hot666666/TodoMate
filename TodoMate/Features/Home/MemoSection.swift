//
//  MemoSection.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import SwiftUI

struct MemoSection: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(MemoStore.self) private var memoStore
  @Environment(HomeScreenVM.self) private var homeScreenVM

  private var currentMemo: Memo? {
    memoStore.memos[homeScreenVM.selectedUserId] ?? nil
  }

  private var isMyMemo: Bool {
    sessionStore.userId == homeScreenVM.selectedUserId
  }

  private func saveMemo(content: String) {
    memoStore.save(content, currentUserId: sessionStore.userId)
  }
}

extension MemoSection {
  var body: some View {
    MarkdownEditor(
      content: currentMemo?.content ?? "",
      isEditable: isMyMemo,
      isEditing: isMyMemo ? Bindable(homeScreenVM).isEditingMemo : .constant(false),
      onSave: saveMemo
    )
    .padding(.horizontal, HomeDesignSystem.Padding.small)
  }
}

#Preview {
  MemoSection()
    .environment(SessionStore.preview)
    .environment(MemoStore.preview)
    .environment(HomeScreenVM())
    .frame(width: 400, height: 300)
}
