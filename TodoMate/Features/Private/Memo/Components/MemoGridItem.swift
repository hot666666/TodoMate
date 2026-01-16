//
//  MemoGridItem.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

import SwiftUI
import TodoMateDomain

struct MemoGridItem: View {
  let memo: Memo
  var onDelete: (() -> Void)?

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
    .contextMenu {
      Button("Copy", systemImage: "doc.on.doc") {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(memo.content, forType: .string)
      }

      Button("Delete", systemImage: "trash", role: .destructive) {
        onDelete?()
      }
    }
  }
}

#Preview {
  MemoGridItem(memo: .stub)
    .frame(width: 200)
    .padding()
}
