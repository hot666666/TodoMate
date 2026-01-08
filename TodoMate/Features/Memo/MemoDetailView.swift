//
//  MemoDetailView.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

import SwiftUI

struct MemoDetailView: View {
  @Environment(MemoStore.self) private var memoStore
  @Environment(SessionStore.self) private var sessionStore

  @Binding var memo: Memo
  let namespace: Namespace.ID
  let onDismiss: () -> Void

  @State private var editedContent: String = ""
  @State private var showDeleteConfirmation = false
  @FocusState private var isEditing: Bool

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Button {
          saveAndDismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.title2)
        }
        .buttonStyle(.plain)

        Spacer()

        Button(role: .destructive) {
          showDeleteConfirmation = true
        } label: {
          Image(systemName: "trash")
            .font(.title3)
        }
        .buttonStyle(.plain)
      }
      .padding()

      // Content Editor
      TextEditor(text: $editedContent)
        .font(.body)
        .scrollContentBackground(.hidden)
        .focused($isEditing)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Footer
      HStack {
        Text("Updated \(memo.updatedAt.formatted(.relative(presentation: .named)))")
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(memo.wordCount) words")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding()
    }
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 16))
    .matchedGeometryEffect(id: memo.id, in: namespace)
    .onAppear {
      editedContent = memo.content
    }
    .confirmationDialog(
      "Delete Memo?", isPresented: $showDeleteConfirmation, titleVisibility: .visible,
    ) {
      Button("Delete", role: .destructive) {
        Task {
          await memoStore.delete(memo, currentUserId: sessionStore.userId)
          onDismiss()
        }
      }
      Button("Cancel", role: .cancel) {}
    }
  }

  private func saveAndDismiss() {
    if editedContent != memo.content {
      memo = memo.withUpdatedContent(editedContent)
      memoStore.update(memo, currentUserId: sessionStore.userId)
    }
    onDismiss()
  }
}

#Preview {
  @Previewable @Namespace var namespace
  @Previewable @State var memo = Memo.stub
  MemoDetailView(memo: $memo, namespace: namespace) {}
    .environment(MemoStore.preview)
    .environment(SessionStore.preview)
    .frame(width: 400, height: 500)
    .padding()
}
