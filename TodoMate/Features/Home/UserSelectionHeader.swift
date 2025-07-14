//
//  UserSelectionHeader.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import SwiftUI

struct UserSelectionHeader: View {
  @Environment(SessionStore.self) private var sessionStore
  @Binding var selectedUserId: String
  @Binding var showDropdown: Bool
  var isEditingMemo: Bool

  var body: some View {
    UserSegmentedControl(
      users: sessionStore.userGroup,
      selectedUserId: $selectedUserId,
      showDropdown: $showDropdown,
      isEditingMemo: isEditingMemo
    )
  }
}

#Preview {
  @State @Previewable var selectedUserId = "user1"
  @State @Previewable var showDropdown = false

  UserSelectionHeader(
    selectedUserId: $selectedUserId,
    showDropdown: $showDropdown,
    isEditingMemo: false
  )
  .environment(SessionStore.preview)
  .frame(width: 300, height: 100)
}
