//
//  EmptyTodoStateView.swift
//  Todo
//
//  Created by hs on 7/10/25.
//

import SwiftUI

struct EmptyTodoListView: View {
  var body: some View {
    VStack(spacing: 6) {
      Label("등록된 할일이 없습니다", systemImage: "tray")
        .font(.headline)
        .fontWeight(.medium)
        .foregroundStyle(.primary)

      Text("아직 할일을 추가하지 않았습니다")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(32)
  }
}

#Preview {
  EmptyTodoListView()
    .frame(height: 300)
    .background(.gray.opacity(0.1))
}
