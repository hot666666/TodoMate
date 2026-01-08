//
//  MemoGridItem.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

import SwiftUI

struct MemoGridItem: View {
  let memo: Memo
  let namespace: Namespace.ID

  private var previewContent: String {
    let lines = memo.content.components(separatedBy: .newlines)
    let limitedLines = lines.prefix(8)
    return limitedLines.joined(separator: "\n")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(previewContent)
        .font(.body)
        .lineLimit(8)
        .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      Text(memo.updatedAt.formatted(.dateTime.month().day()))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(minHeight: 120)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
    .matchedGeometryEffect(id: memo.id, in: namespace)
  }
}

#Preview {
  @Previewable @Namespace var namespace
  MemoGridItem(memo: .stub, namespace: namespace)
    .frame(width: 200)
    .padding()
}
