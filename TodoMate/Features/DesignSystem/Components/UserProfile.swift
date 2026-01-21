//
//  UserProfile.swift
//  TodoMate
//
//  Created by agent on 1/13/26.
//

import SwiftUI

/// 사용자 프로필 뷰 스타일
struct UserProfile<Avatar: View, LeadingAction: View, TrailingAction: View>: View {
  let displayName: String
  let style: ProfileAvatarStyle
  @ViewBuilder let avatar: () -> Avatar
  @ViewBuilder let leadingAction: () -> LeadingAction
  @ViewBuilder let trailingAction: () -> TrailingAction

  init(
    displayName: String,
    style: ProfileAvatarStyle = .compact,
    @ViewBuilder avatar: @escaping () -> Avatar,
    @ViewBuilder leadingAction: @escaping () -> LeadingAction = { EmptyView() },
    @ViewBuilder trailingAction: @escaping () -> TrailingAction = { EmptyView() },
  ) {
    self.displayName = displayName
    self.style = style
    self.avatar = avatar
    self.leadingAction = leadingAction
    self.trailingAction = trailingAction
  }

  var body: some View {
    HStack {
      ProfileAvatar(style: style) {
        avatar()
      } label: {
        VStack(alignment: .leading, spacing: 5) {
          Text(displayName)
            .font(style == .compact ? .subheadline : .title3)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        }
      } action: {
        leadingAction()
      }

      if style == .default {
        Spacer()
        trailingAction()
      }
    }
  }
}

// MARK: - Convenience Init for DefaultAvatar

extension UserProfile where Avatar == DefaultAvatar {
  init(
    displayName: String,
    style: ProfileAvatarStyle = .compact,
    size: CGFloat = 32,
    @ViewBuilder leadingAction: @escaping () -> LeadingAction = { EmptyView() },
    @ViewBuilder trailingAction: @escaping () -> TrailingAction = { EmptyView() },
  ) {
    self.displayName = displayName
    self.style = style
    avatar = { DefaultAvatar(displayName: displayName, size: size) }
    self.leadingAction = leadingAction
    self.trailingAction = trailingAction
  }
}

// MARK: - Previews

#Preview("Sidebar Style") {
  UserProfile(
    displayName: "홍길동",
    style: .compact,
    size: 32,
  )
  .padding()
}

#Preview("Setting Style") {
  UserProfile(
    displayName: "홍길동",
    style: .default,
    size: 64,
  ) {
    Button("로그아웃") {}
      .buttonStyle(.bordered)
      .tint(.red)
  } trailingAction: {
    Button("수정") {}
      .buttonStyle(.bordered)
  }
  .padding()
}
