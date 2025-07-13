//
//  UserSegmentedControl.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import SwiftUI

struct UserSegmentedControl: View {
  let users: [User]
  @Binding var selectedUserId: String
  @Binding var showDropdown: Bool
  var isEditingMemo: Bool

  private func updateSelectedUserIfPossible(user: User) {
    guard !isEditingMemo else { return }
    selectedUserId = user.id
  }
}

extension UserSegmentedControl {
  var body: some View {
    HStack(spacing: HomeDesignSystem.Spacing.none) {
      ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
        let isSelected = user.id == selectedUserId

        userSegment(user: user, isSelected: isSelected)
          .onTapGesture {
            updateSelectedUserIfPossible(user: user)
          }
          .overlay(alignment: .leading) {
            dropDownButton
              .opacity(isSelected ? 1 : 0)
          }

        if index < users.count - 1 {
          Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 1, height: HomeDesignSystem.Component.UserPicker.dividerHeight)
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: HomeDesignSystem.CornerRadius.large)
        .stroke(Color.secondary.opacity(0.3), lineWidth: HomeDesignSystem.Stroke.thin)
    )
  }

  private var dropDownButton: some View {
    Button {
      showDropdown.toggle()
    } label: {
      Image(systemName: showDropdown ? "chevron.down" : "chevron.right")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(
          width: HomeDesignSystem.Component.UserPicker.iconSize,
          height: HomeDesignSystem.Component.UserPicker.iconSize
        )
        .padding(.horizontal, HomeDesignSystem.Component.UserPicker.dropdownHorizontalPadding)
        .padding(.vertical, HomeDesignSystem.Component.UserPicker.dropdownVerticalPadding)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .frame(height: HomeDesignSystem.Component.UserPicker.dividerHeight)
    .padding(.leading, HomeDesignSystem.Padding.xSmall)
  }

  private func userSegment(user: User, isSelected: Bool) -> some View {
    Text(user.displayName)
      .bold(isSelected)
      .foregroundStyle(isSelected ? .primary : .secondary)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .frame(height: HomeDesignSystem.Component.UserPicker.buttonHeight)
      .contentShape(.rect(cornerRadius: HomeDesignSystem.CornerRadius.small))
      .opacity(isEditingMemo && !isSelected ? 0.5 : 1.0)
  }
}

#Preview {
  @State @Previewable var selectedUserId = "user1"
  @State @Previewable var showDropdown = false
  @State @Previewable var isEditing = false

  UserSegmentedControl(
    users: [
      User(id: "user1", displayName: "User 1", groupId: "group1"),
      User(id: "user2", displayName: "User 2", groupId: "group1"),
    ],
    selectedUserId: $selectedUserId,
    showDropdown: $showDropdown,
    isEditingMemo: isEditing
  )
  .frame(width: 300, height: 200)
  .padding()
}
