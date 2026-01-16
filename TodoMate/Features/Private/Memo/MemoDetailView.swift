//
//  MemoDetailView.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

import AppKit
import SwiftUI
import SwiftUIIntrospect
import TodoMateDomain

struct MemoDetailView: View {
  @State private var cleared = false
  let memo: Memo
  let namespace: Namespace.ID
  let onDismiss: () -> Void
  let onSave: (String) -> Void
  let onDelete: () -> Void

  @State private var editedContent: String = ""
  @FocusState private var isEditing: Bool

  private var isEmpty: Bool {
    editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      // Content Editor
      TextEditor(text: $editedContent)
        .font(.body)
        .scrollContentBackground(.hidden)
        .opacity(cleared ? 1 : 0)
        .focused($isEditing)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .introspect(.textEditor, on: .macOS(.v26)) { textView in
          textView.drawsBackground = false
          if let scrollView = textView.enclosingScrollView {
            scrollView.drawsBackground = false
            scrollView.contentView.drawsBackground = false
            scrollView.scrollerStyle = .overlay
            scrollView.autohidesScrollers = true
          }
          // Reveal after styles applied to avoid first-frame flash
          DispatchQueue.main.async { cleared = true }
        }

      // Footer
      HStack {
        Text("Updated \(memo.updatedAt.formatted(.relative(presentation: .named)))")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.regularMaterial)
    .matchedGeometryEffect(id: memo.id, in: namespace)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          saveOrDeleteAndDismiss()
        } label: {
          Image(systemName: "chevron.left")
        }
      }

      ToolbarItem(placement: .secondaryAction) {
        Menu {
          Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(memo.content, forType: .string)
          } label: {
            Label("Copy Text", systemImage: "doc.on.doc")
          }

          Divider()

          Button(role: .destructive) {
            onDelete()
            // onDismiss is called by helper in MemoView usually, but here onDelete is passed from MemoView which includes dismiss.
            // Let's check MemoView: deleteMemo calls store.delete() AND dismissDetail().
            // So we just call onDelete().
          } label: {
            Label("Delete", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .onAppear {
      editedContent = memo.content
    }
  }

  private func saveOrDeleteAndDismiss() {
    if isEmpty {
      onDelete()
    } else {
      onSave(editedContent)
    }
    onDismiss()
  }
}

#Preview {
  @Previewable @Namespace var namespace
  MemoDetailView(
    memo: .stub,
    namespace: namespace,
    onDismiss: {},
    onSave: { _ in },
    onDelete: {},
  )
  .environment(LocalMemoHelper(container: .preview))
  .environment(SessionStore.preview)
  .frame(width: 400, height: 500)
}
