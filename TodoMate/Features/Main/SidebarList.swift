//
//  SidebarList.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct SidebarList: View {
  @Environment(SessionStore.self) private var sessionStore
  @Binding var selectedScreen: Sidebar

  private var sidebarItems: [Sidebar] {
    sessionStore.userGroup.map { Sidebar.user($0) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SidebarConstants.itemSpacing) {
      // MARK: - 그룹 섹션

      if !sidebarItems.isEmpty {
        SidebarSectionHeader(title: "그룹")

        ForEach(sidebarItems, id: \.id) { screen in
          SidebarItem(
            isSelected: selectedScreen.id == screen.id,
            onTap: { selectedScreen = screen }
          ) {
            Text(screen.title)
          }
        }
      }

      Spacer()

      // MARK: - 프로필 섹션

      SidebarItem(
        isSelected: selectedScreen.id == Sidebar.profile.id,
        onTap: { selectedScreen = .profile }
      ) {
        Label(Sidebar.profile.title, systemImage: "person.circle.fill")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(SidebarConstants.containerPadding)
    .background(SidebarConstants.backgroundColor)
  }
}
