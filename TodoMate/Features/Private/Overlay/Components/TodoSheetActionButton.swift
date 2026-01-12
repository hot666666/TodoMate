//
//  TodoSheetActionButton.swift
//  TodoMate
//
//  Created by agent on 1/7/26.
//

import SwiftUI

/// Todo Sheet 하단의 단일 액션 버튼
/// 상태 변화에 따라 SF Symbol 전환 애니메이션으로 xmark ↔ checkmark/plus 전환
struct TodoSheetActionButton: View {
  /// 변경사항 존재 여부
  let hasChanges: Bool
  /// 새 Todo 생성 여부 (true: plus, false: checkmark)
  let isNew: Bool
  /// 저장 액션
  let onSave: () -> Void
  /// 닫기/폐기 액션
  let onDismiss: () -> Void

  /// 현재 표시할 심볼 이름
  private var symbolName: String {
    if hasChanges {
      isNew ? "plus" : "checkmark"
    } else {
      "xmark"
    }
  }

  var body: some View {
    Button {
      if hasChanges {
        onSave()
      } else {
        onDismiss()
      }
    } label: {
      Image(systemName: symbolName)
        .contentTransition(.symbolEffect(.replace))
        .font(.callout)
        .bold()
        .foregroundStyle(hasChanges ? .primary : .secondary)
        .frame(width: 26, height: 26)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .padding(5)
    .frame(height: 36)
    .background(.ultraThinMaterial)
    .clipShape(Capsule())
    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasChanges)
  }
}

#Preview {
  @Previewable @State var hasChanges = false

  VStack(spacing: 20) {
    Text("hasChanges: \(hasChanges ? "true" : "false")")

    TodoSheetActionButton(
      hasChanges: hasChanges,
      isNew: true,
      onSave: { print("Save") },
      onDismiss: { print("Dismiss") },
    )

    TodoSheetActionButton(
      hasChanges: hasChanges,
      isNew: false,
      onSave: { print("Save") },
      onDismiss: { print("Dismiss") },
    )

    Button("Toggle") {
      hasChanges.toggle()
    }
  }
  .padding()
  .background(Color.gray.opacity(0.2))
}
