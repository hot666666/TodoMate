//
//  PageHeader.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI

/// 공통 페이지 헤더 컴포넌트
struct PageHeader<TrailingContent: View>: View {
  // MARK: - Properties

  let title: String
  @ViewBuilder let trailingContent: () -> TrailingContent

  // MARK: - Body

  var body: some View {
    HStack(alignment: .bottom) {
      Text(title)
        .font(.title)
        .foregroundStyle(.primary)

      Spacer()

      trailingContent()
    }
    .padding(.horizontal)
    .padding(.top, 8)
  }
}

extension PageHeader where TrailingContent == EmptyView {
  init(title: String) {
    self.title = title
    trailingContent = { EmptyView() }
  }
}
