//
//  DeletedItemRow.swift
//  TodoMate
//
//  Created by agent on 1/22/26.
//

import SwiftUI
import TodoMateDomain

/// A single row representing a deleted item (Todo or Memo) in the trash list.
struct DeletedItemRow: View {
  let item: DeletedItem
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 12) {
      selectionIndicator
      itemIcon
      itemContent
      Spacer()
      deletedAtLabel
    }
    .padding(.vertical, 4)
    .contentShape(.rect)
  }

  // MARK: - Subviews

  private var selectionIndicator: some View {
    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
      .foregroundStyle(isSelected ? DesignSystem.Colors.primary : .secondary)
      .font(.title3)
  }

  private var itemIcon: some View {
    Group {
      switch item {
      case .todo:
        Image(systemName: "checkmark.circle")
          .foregroundStyle(DesignSystem.Colors.primary)
      case .memo:
        Image(systemName: "square.text.square")
          .foregroundStyle(DesignSystem.Colors.trafficYellow)
      }
    }
    .font(.title3)
  }

  private var itemContent: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(item.displayContent)
        .lineLimit(1)
        .font(.body)

      Text(itemTypeLabel)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var deletedAtLabel: some View {
    Text(item.deletedAt, style: .relative)
      .font(.caption)
      .foregroundStyle(.tertiary)
  }

  private var itemTypeLabel: String {
    switch item {
    case .todo: "Todo"
    case .memo: "Memo"
    }
  }
}

// MARK: - Preview

#Preview {
  List {
    DeletedItemRow(
      item: .todo(Todo(owner: "user1", content: "Sample Todo", in: Date())),
      isSelected: false,
    )
    DeletedItemRow(
      item: .memo(Memo(owner: "user1", content: "Sample Memo", date: Date())),
      isSelected: true,
    )
  }
}
