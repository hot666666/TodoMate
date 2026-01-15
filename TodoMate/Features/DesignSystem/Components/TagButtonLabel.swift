//
//  TagButtonLabel.swift
//  TodoMate
//
//  Created by agent on 1/7/26.
//

import SwiftUI

/// 태그 스타일의 레이블 컴포넌트
/// 아이콘 + 텍스트 조합으로 태그 형태의 라벨 제공
struct TagButtonLabel: View {
  let icon: String
  let text: String
  let isActive: Bool
  let activeColor: Color
  var isExpanded: Bool = false

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
      Text(text)
    }
    .tagButtonStyle(
      isActive: isActive,
      activeColor: activeColor,
      isExpanded: isExpanded,
    )
  }
}

#Preview {
  VStack(spacing: 16) {
    TagButtonLabel(
      icon: "calendar",
      text: "오늘",
      isActive: true,
      activeColor: .green,
    )

    TagButtonLabel(
      icon: "circle.fill",
      text: "진행중",
      isActive: true,
      activeColor: .blue,
      isExpanded: true,
    )

    TagButtonLabel(
      icon: "circle",
      text: "할 일",
      isActive: false,
      activeColor: .gray,
    )
  }
  .padding()
}
