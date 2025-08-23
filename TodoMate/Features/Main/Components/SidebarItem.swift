//
//  SidebarItem.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct SidebarItem<Content: View>: View {
  let isSelected: Bool
  let onTap: () -> Void
  let content: Content

  @State private var isHovered = false

  init(
    isSelected: Bool,
    onTap: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.isSelected = isSelected
    self.onTap = onTap
    self.content = content()
  }

  var body: some View {
    HStack {
      content
        .foregroundColor(isSelected ? .white : .secondary)
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, SidebarConstants.itemPaddingHorizontal)
    .padding(.vertical, SidebarConstants.itemPaddingVertical)
    .background {
      if isSelected {
        selectedBackground
      } else if isHovered {
        hoverBackground
      } else {
        Color.clear
      }
    }
    .contentShape(.rect)
    .onTapGesture(perform: onTap)
    .onHover { hovering in
      withAnimation(SidebarConstants.hoverAnimation) {
        isHovered = hovering
      }
    }
    .accessibilityAddTraits(.isButton)
    .accessibilityHint(isSelected ? "현재 선택됨" : "탭하여 선택")
  }

  private var selectedBackground: some View {
    RoundedRectangle(cornerRadius: SidebarConstants.itemCornerRadius)
      .fill(.ultraThinMaterial.opacity(SidebarConstants.selectedBackgroundOpacity))
      .overlay(
        RoundedRectangle(cornerRadius: SidebarConstants.itemCornerRadius)
          .stroke(Color.white.opacity(SidebarConstants.selectedBorderOpacity), lineWidth: 1)
      )
      .animation(SidebarConstants.selectionAnimation, value: isSelected)
  }

  private var hoverBackground: some View {
    RoundedRectangle(cornerRadius: SidebarConstants.itemCornerRadius)
      .fill(.ultraThinMaterial.opacity(0.3))
      .overlay(
        RoundedRectangle(cornerRadius: SidebarConstants.itemCornerRadius)
          .stroke(Color.white.opacity(0.1), lineWidth: 1)
      )
  }
}

#Preview {
  VStack(spacing: 8) {
    SidebarItem(isSelected: true, onTap: {}) {
      Text("선택된 항목")
    }

    SidebarItem(isSelected: false, onTap: {}) {
      Label("프로필", systemImage: "person.circle.fill")
    }

    SidebarItem(isSelected: false, onTap: {}) {
      Text("일반 항목")
    }
  }
  .padding()
  .background(Color.customBlack)
  .preferredColorScheme(.dark)
}
