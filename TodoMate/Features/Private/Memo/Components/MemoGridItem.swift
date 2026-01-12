//
//  MemoGridItem.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

import SwiftUI

struct MemoGridItem: View {
  let memo: Memo

  private var previewContent: String {
    let lines = memo.content.components(separatedBy: .newlines)
    let limitedLines = lines.prefix(6)
    return limitedLines.joined(separator: "\n")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(previewContent)
        .font(.body)
        .lineLimit(6)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .topLeading)

      Spacer()

      Text(memo.updatedAt.formatted(.dateTime.month().day()))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(minHeight: 150)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
  }
}

#Preview {
  MemoGridItem(memo: .stub)
    .frame(width: 200)
    .padding()
}
