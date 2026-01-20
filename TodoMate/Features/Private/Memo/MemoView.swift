//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//
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
    .onGlobalHotKey(.escape) {
      if isDetailViewPresented {
        dismissDetail()
      }
    }
  }

  // MARK: - Subviews

  private var contentView: some View {
    VStack(alignment: .leading, spacing: 16) {
      header

      if store.memos.isEmpty {
        emptyState
      } else {
        memoGrid
      }
    }
  }

  private var header: some View {
    HStack {
      Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
        .font(.title)

      Spacer()
    }
    .padding(.horizontal)
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
          MemoGridItem(memo: memo) {
            deleteMemo(memo)
          }
          .matchedGeometryEffect(id: memo.id, in: heroNamespace)
          .onTapGesture {
            selectMemo(memo)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
  }

  private func detailView(for memo: Memo) -> some View {
    MemoDetailView(
      memo: memo,
      namespace: heroNamespace,
      onDismiss: dismissDetail,
      onSave: { updatedContent in
        saveMemo(memo, with: updatedContent)
      },
      onDelete: {
        deleteMemo(memo)
      },
    )
  }

  // MARK: - Actions

  private func addNewMemo() {
    store.add(content: "New Memo")
  }

  private func selectMemo(_ memo: Memo) {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      selectedMemo = memo
      isDetailViewPresented = true
    }
  }

  private func saveMemo(_ memo: Memo, with newContent: String) {
    if newContent != memo.content {
      let updatedMemo = memo.withUpdatedContent(newContent)
      store.update(updatedMemo)
    }
  }

  private func deleteMemo(_ memo: Memo) {
    store.delete(memo)
    dismissDetail()
  }

  private func dismissDetail() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      isDetailViewPresented = false
    }
  }
}

#Preview {
  MemoView()
    .environment(MemoStore.preview)
}
