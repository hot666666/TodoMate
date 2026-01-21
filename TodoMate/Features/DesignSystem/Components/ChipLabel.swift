//
//  ChipLabel.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI

/// 아이콘 + 텍스트 형태의 칩 라벨
struct ChipLabel: View {
  let icon: String
  let text: String
  var isActive: Bool = false
  var color: Color = .primary
  var isExpanded: Bool = false

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
      Text(text)
    }
    .chipStyle(isActive: isActive, color: color, isExpanded: isExpanded)
  }
}

#Preview("ChipLabel") {
  VStack(spacing: 16) {
    ChipLabel(icon: "calendar", text: "오늘", isActive: true, color: .green)
    ChipLabel(icon: "circle.fill", text: "진행중", isActive: true, color: .blue, isExpanded: true)
    ChipLabel(icon: "circle", text: "할 일", isActive: false, color: .gray)
  }
  .padding()
}
