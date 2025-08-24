//
//  SidebarSectionHeader.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct SidebarSectionHeader: View {
  let title: String

  var body: some View {
    Text(title)
      .font(SidebarDesignSystem.sectionHeaderFont)
      .fontWeight(.semibold)
      .foregroundColor(.white.opacity(SidebarDesignSystem.sectionHeaderOpacity))
      .textCase(.uppercase)
      .padding(.horizontal, SidebarDesignSystem.itemPaddingHorizontal)
      .padding(.top, 4)
      .padding(.bottom, 2)
      .accessibilityAddTraits(.isHeader)
  }
}

#Preview {
  SidebarSectionHeader(title: "그룹")
    .background(Color.customBlack)
    .preferredColorScheme(.dark)
}
