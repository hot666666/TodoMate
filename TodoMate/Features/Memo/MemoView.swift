//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI
import TodoMateDomain

// MARK: - MemoView

struct MemoView: View {
  // MARK: - Environment

  @Environment(MemoStore.self) private var store

  // MARK: - State

  @Namespace private var heroNamespace
  @State private var selectedMemo: Memo?
  @State private var isDetailViewPresented = false

  private var headerTitle: String {
    Date().formatted(.dateTime.year().month().day().weekday(.wide))
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      Color(nsColor: .windowBackgroundColor)
        .ignoresSafeArea()

      if let selectedMemo, isDetailViewPresented {
        detailView(for: selectedMemo)
          .transition(.asymmetric(insertion: .identity, removal: .opacity))
          .zIndex(1)
      } else {
        contentView
      }
    }
    .toolbar {
      if !isDetailViewPresented {
        ToolbarItem(placement: .primaryAction) {
          Button {
            addNewMemo()
          } label: {
            Image(systemName: "plus")
          }
          .keyboardShortcut("n", modifiers: .command)
        }
      }
    }
    .accessibilityIdentifier("memoView")
    .onKeyPress(.escape) {
      if isDetailViewPresented { dismissDetail() }
      return .handled
    }
  }

  private var contentView: some View {
    VStack(alignment: .leading, spacing: 16) {
      PageHeader(title: headerTitle)

      if store.memos.isEmpty {
        emptyState
      } else {
        memoGrid
      }
    }
  }

  private var emptyState: some View {
    ContentUnavailableView(
      "No Memos",
      systemImage: "square.text.square",
      description: Text("Tap the + button to create a memo"),
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var memoGrid: some View {
    let columns = [
      GridItem(.adaptive(minimum: 180, maximum: 300), spacing: 16),
    ]

    return ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(store.memos) { memo in
          MemoGridItem(memo: memo) { deleteMemo(memo) }
            .matchedGeometryEffect(id: memo.id, in: heroNamespace)
            .onTapGesture { selectMemo(memo) }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
  }

  private func detailView(for memo: Memo) -> some View {
    MemoDetail(
      memo: memo,
      namespace: heroNamespace,
      onDismiss: dismissDetail,
      onSave: { updatedContent in saveMemo(memo, with: updatedContent) },
      onDelete: { deleteMemo(memo) },
      onPermanentlyDelete: { permanentlyDeleteMemo(memo) },
    )
  }
}

// MARK: - Actions

private extension MemoView {
  func addNewMemo() {
    store.add(content: "New Memo")
  }

  func selectMemo(_ memo: Memo) {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      selectedMemo = memo
      isDetailViewPresented = true
    }
  }

  func saveMemo(_ memo: Memo, with newContent: String) {
    if newContent != memo.content {
      let updatedMemo = memo.withUpdatedContent(newContent)
      store.update(updatedMemo)
    }
  }

  /// Soft delete - puts memo in trash (used by context menu)
  func deleteMemo(_ memo: Memo) {
    store.delete(memo)
    dismissDetail()
  }

  /// Hard delete - removes memo permanently (used when content is cleared)
  func permanentlyDeleteMemo(_ memo: Memo) {
    store.permanentlyDelete(memo)
    dismissDetail()
  }

  func dismissDetail() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      isDetailViewPresented = false
    }
  }
}

#Preview {
  MemoView()
    .environment(MemoStore.preview)
}
