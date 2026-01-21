//
//  ScrollableSegmentedControl.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI

/// 수평 스크롤 가능한 세그먼트 컨트롤
struct ScrollableSegmentedControl<T: Identifiable & Hashable>: View {
  // MARK: - Properties

  let items: [T]
  @Binding var selection: T.ID?
  let label: (T) -> String

  // MARK: - State

  @Namespace private var segmentAnimation

  // MARK: - Body

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(items) { item in
          let isSelected = selection == item.id
          Text(label(item))
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background {
              if isSelected {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.blue)
                  .matchedGeometryEffect(id: "segment", in: segmentAnimation)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              withAnimation(.snappy) {
                selection = item.id
              }
            }
        }
      }
      .padding(4)
      .background(Color(nsColor: .controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }
}
