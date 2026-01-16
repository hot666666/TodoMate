//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//
//

import SimpleOverlaySystem
import SwiftData
import SwiftUI
import TodoMateDomain

// MARK: - MemoView (Container)

struct MemoView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(LocalMemoHelper.self) private var memoStore

  @State private var selectedMemo: Memo?
  @State private var escToken: HotKeyManager.RegistrationToken?
  @Namespace private var heroNamespace
  @State private var isDetailViewPresented = false

  var body: some View {
    ZStack {
      // Background
      Color(nsColor: .windowBackgroundColor)
        .ignoresSafeArea()

      if let selectedMemo, isDetailViewPresented {
        // Detail View
        MemoDetailView(
          memo: selectedMemo,
          namespace: heroNamespace,
          onDismiss: dismissDetail,
          onSave: { updatedContent in
            saveMemo(selectedMemo, with: updatedContent)
          },
          onDelete: {
            deleteMemo(selectedMemo)
          },
        )
        .transition(.asymmetric(insertion: .identity, removal: .opacity))
        .zIndex(1)
      } else {
        // Query Wrapper & Content
        MemoQueryWrapper(
          heroNamespace: heroNamespace,
          onTapMemo: { memo in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
              selectedMemo = memo
              isDetailViewPresented = true
            }
          },
          onDeleteMemo: deleteMemo,
        )
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
    // ESC Handling
    .onAppear { registerESCHandler() }
    .onDisappear { unregisterESCHandler() }
    .onChange(of: isDetailViewPresented) { _, isPresented in
      if isPresented {
        registerESCHandler()
      }
    }
  }

  // MARK: - Actions

  private func addNewMemo() {
    // Add via store (fire & forget, Query will update UI)
    memoStore.add(content: "")
  }

  private func saveMemo(_ memo: Memo, with newContent: String) {
    if newContent != memo.content {
      let updatedMemo = memo.withUpdatedContent(newContent)
      memoStore.update(updatedMemo)
    }
  }

  private func deleteMemo(_ memo: Memo) {
    Task {
      memoStore.delete(memo)
      dismissDetail()
    }
  }

  private func dismissDetail() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      selectedMemo = nil
      isDetailViewPresented = false
    }
  }

  // MARK: - HotKey

  private func registerESCHandler() {
    if escToken == nil {
      escToken = container.core.hotKeyManager.register(key: .escape, modifiers: []) {
        Task { @MainActor in
          if isDetailViewPresented {
            dismissDetail()
          }
        }
      }
    }
  }

  private func unregisterESCHandler() {
    if let token = escToken {
      container.core.hotKeyManager.unregister(token)
      escToken = nil
    }
  }
}

// MARK: - MemoQueryWrapper (Data Access)

private struct MemoQueryWrapper: View {
  @Query(
    filter: #Predicate<SDMemo> { !$0.isDeleted },
    sort: \SDMemo.createdAt,
    order: .reverse,
  )
  private var sdMemos: [SDMemo]

  let heroNamespace: Namespace.ID
  let onTapMemo: (Memo) -> Void
  let onDeleteMemo: (Memo) -> Void

  var body: some View {
    // Convert SDMemo -> Memo (Domain)
    let memos = sdMemos.map { $0.toDomain() }

    MemoContent(
      memos: memos,
      heroNamespace: heroNamespace,
      onTapMemo: onTapMemo,
      onDeleteMemo: onDeleteMemo,
    )
  }
}

// MARK: - MemoContent (Pure UI)

private struct MemoContent: View {
  let memos: [Memo]
  let heroNamespace: Namespace.ID
  let onTapMemo: (Memo) -> Void
  let onDeleteMemo: (Memo) -> Void

  private let columns = [
    GridItem(.adaptive(minimum: 180, maximum: 300), spacing: 16),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Date Header
      HStack {
        Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
          .font(.title)

        Spacer()
      }
      .padding(.horizontal)

      if memos.isEmpty {
        ContentUnavailableView(
          "No Memos",
          systemImage: "square.text.square",
          description: Text("Tap the + button to create a memo"),
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(memos) { memo in
              MemoGridItem(
                memo: memo,
                onDelete: { onDeleteMemo(memo) },
              )
              .matchedGeometryEffect(id: memo.id, in: heroNamespace)
              .onTapGesture {
                onTapMemo(memo)
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 20)
        }
      }
    }
  }
}

#Preview {
  MemoView()
    .environment(LocalMemoHelper.preview)
    .environment(OverlayManager())
}
