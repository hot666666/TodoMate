//
//  ProfileAvatarView.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import SwiftUI

/// 프로필 아바타 컴포넌트
/// Settings와 Sidebar에서 공유하여 일관된 프로필 이미지 스타일 제공
struct ProfileAvatarView: View {
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

#Preview("Large") {
  ProfileAvatarView(displayName: "홍길동", size: 64)
}

#Preview("Medium") {
  ProfileAvatarView(displayName: "Guest", size: 40)
}

#Preview("Small") {
  ProfileAvatarView(displayName: "AB", size: 32)
}
