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
  var selectedUserId: String
  @Binding var isEditingMemo: Bool

  private var currentMemo: Memo? {
    memoStore.memos[selectedUserId] ?? nil
  }

  private var isMyMemo: Bool {
    sessionStore.userId == selectedUserId
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
      isEditing: isMyMemo ? $isEditingMemo : .constant(false),
      onSave: saveMemo
    )
    .padding(.horizontal, HomeDesignSystem.Padding.small)
  }
}

#Preview {
  @State @Previewable var isEditingMemo = false

  MemoSection(
    selectedUserId: "user1",
    isEditingMemo: $isEditingMemo
  )
  .environment(SessionStore.preview)
  .environment(MemoStore.preview)
  .frame(width: 400, height: 300)
}
