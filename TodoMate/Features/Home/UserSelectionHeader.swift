//
//  UserSelectionHeader.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import SwiftUI

struct UserSelectionHeader: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(HomeScreenVM.self) private var homeScreenVM

  var body: some View {
    UserSegmentedControl(
      users: sessionStore.userGroup,
      selectedUserId: Bindable(homeScreenVM).selectedUserId,
      showDropdown: Bindable(homeScreenVM).showDropdown,
      isEditingMemo: homeScreenVM.isEditingMemo
    )
  }
}

#Preview {
  UserSelectionHeader()
    .environment(HomeScreenVM())
    .environment(SessionStore.preview)
    .frame(width: 300, height: 100)
}
