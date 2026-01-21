//
//  AvatarPile.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI
import TodoMateDomain

// MARK: - AvatarPile는 아바타 스택 (예: 그룹 멤버 표시)

struct AvatarPile: View {
  // MARK: - Properties

  let members: [User]
  var limit: Int = 3
  var avatarSize: CGFloat = 32
  var overlapOffset: CGFloat = -10
  var strokeColor: Color = .white
  var strokeWidth: CGFloat = 2

  // MARK: - Body

  var body: some View {
    HStack(spacing: overlapOffset) {
      ForEach(members.prefix(limit)) { member in
        DefaultAvatar(displayName: member.displayName, size: avatarSize)
          .overlay(Circle().stroke(strokeColor, lineWidth: strokeWidth))
      }

      if members.count > limit {
        Text("+\(members.count - limit)")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .frame(width: avatarSize, height: avatarSize)
          .background(Color.gray.opacity(0.1))
          .clipShape(Circle())
          .overlay(Circle().stroke(strokeColor, lineWidth: strokeWidth))
      }
    }
  }
}
