//
//  SidebarList.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct SidebarList: View {
  @Environment(SessionStore.self) private var sessionStore
  @Binding var item: Sidebar

  private var sidebarItems: [Sidebar] {
    sessionStore.userGroup.map { Sidebar.user($0) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SidebarDesignSystem.itemSpacing) {
      // MARK: - 그룹 섹션

      if !sidebarItems.isEmpty {
        SidebarSectionHeader(title: "그룹")

        ForEach(sidebarItems, id: \.id) { sidebar in
          SidebarItem(
            isSelected: item.id == sidebar.id,
            onTap: { item = sidebar },
          ) {
            Text(sidebar.title)
          }
        }
      }

      Spacer()

      // MARK: - 프로필 섹션

      SidebarItem(
        isSelected: item.id == Sidebar.profile.id,
        onTap: { item = .profile },
      ) {
        Label(Sidebar.profile.title, systemImage: "person.circle.fill")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(SidebarDesignSystem.containerPadding)
    .background(SidebarDesignSystem.backgroundColor)
  }
}
