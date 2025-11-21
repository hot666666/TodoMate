//
//  EmptyStateView.swift
//  TodoMate
//
//  Created by hs on 7/21/25.
//

import SwiftUI

/// 제네릭 Empty State 컴포넌트
struct EmptyStateView: View {
  let icon: String
  let title: String
  let subtitle: String?

  init(
    icon: String = "tray",
    title: String,
    subtitle: String? = nil
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(spacing: 6) {
      Label(title, systemImage: icon)
        .font(.headline)
        .fontWeight(.medium)
        .foregroundStyle(.primary)

      if let subtitle {
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(32)
  }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
  /// 빈 할일 목록 상태
  static var emptyTodoList: EmptyStateView {
    EmptyStateView(
      title: "등록된 할일이 없습니다",
      subtitle: "아직 할일을 추가하지 않았습니다"
    )
  }

  /// 빈 메시지 상태
  static var emptyMessages: EmptyStateView {
    EmptyStateView(
      icon: "bubble.left.and.bubble.right",
      title: "메시지가 없습니다",
      subtitle: "첫 메시지를 보내보세요"
    )
  }

  /// 빈 검색 결과
  static var emptySearch: EmptyStateView {
    EmptyStateView(
      icon: "magnifyingglass",
      title: "검색 결과가 없습니다",
      subtitle: "다른 키워드로 검색해보세요"
    )
  }
}

#Preview {
  VStack(spacing: 40) {
    EmptyStateView.emptyTodoList
      .frame(height: 200)
      .background(.gray.opacity(0.1))

    EmptyStateView.emptyMessages
      .frame(height: 200)
      .background(.gray.opacity(0.1))

    EmptyStateView.emptySearch
      .frame(height: 200)
      .background(.gray.opacity(0.1))
  }
  .padding()
}
