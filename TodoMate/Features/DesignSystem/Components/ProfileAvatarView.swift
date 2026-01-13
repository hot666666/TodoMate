//
//  ProfileAvatarView.swift
//  TodoMate
//
//  Created by agent on 1/13/26.
//

import SwiftUI

// MARK: - ProfileAvatarView

enum ProfileAvatarStyle {
  case compact // Action hidden
  case `default` // All visible
}

struct ProfileAvatarView<Avatar: View, Label: View, Action: View>: View {
  let style: ProfileAvatarStyle
  @ViewBuilder let avatar: () -> Avatar
  @ViewBuilder let label: () -> Label
  @ViewBuilder let action: () -> Action

  init(
    style: ProfileAvatarStyle = .default,
    @ViewBuilder avatar: @escaping () -> Avatar,
    @ViewBuilder label: @escaping () -> Label,
    @ViewBuilder action: @escaping () -> Action = { EmptyView() },
  ) {
    self.style = style
    self.avatar = avatar
    self.label = label
    self.action = action
  }

  var body: some View {
    HStack(spacing: style == .compact ? 8 : 16) {
      avatar()

      VStack(alignment: .leading) {
        label()
        if style == .default {
          action()
        }
      }

      Spacer()
    }
  }
}

// MARK: - DefaultAvatar

struct DefaultAvatar: View {
  let displayName: String
  var size: CGFloat = 64

  private var initials: String {
    displayName.isEmpty ? "?" : String(displayName.prefix(2)).uppercased()
  }

  var body: some View {
    Circle()
      .fill(
        LinearGradient(
          colors: [.blue, .purple],
          startPoint: .topLeading,
          endPoint: .bottomTrailing,
        ),
      )
      .frame(width: size, height: size)
      .overlay {
        Text(initials)
          .font(fontSize)
          .fontWeight(.semibold)
          .foregroundStyle(.white)
      }
  }

  private var fontSize: Font {
    switch size {
    case ..<40:
      .caption
    case 40 ..< 60:
      .subheadline
    default:
      .title2
    }
  }
}

// MARK: - Previews

#Preview("Row - Default Style") {
  ProfileAvatarView(style: .default) {
    DefaultAvatar(displayName: "홍길동", size: 64)
  } label: {
    VStack(alignment: .leading, spacing: 2) {
      Text("홍길동")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
      Text("User")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  } action: {
    Button("Edit") {}
      .buttonStyle(.bordered)
  }
  .padding()
}

#Preview("Row - Compact Style") {
  ProfileAvatarView(style: .compact) {
    DefaultAvatar(displayName: "Guest", size: 64)
  } label: {
    Text("Guest")
      .font(.subheadline)
      .fontWeight(.semibold)
      .foregroundStyle(.primary)
  }
  .padding()
}

#Preview("Avatar - Large") {
  DefaultAvatar(displayName: "홍길동", size: 64)
}

#Preview("Avatar - Medium") {
  DefaultAvatar(displayName: "Guest", size: 40)
}

#Preview("Avatar - Small") {
  DefaultAvatar(displayName: "AB", size: 32)
}
