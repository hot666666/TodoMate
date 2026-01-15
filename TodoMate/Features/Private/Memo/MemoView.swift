//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI
import TodoMateDomain

struct MemoView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(PrivateMemoStore.self) private var memoStore

  @State private var selectedMemo: Memo?
  @State private var escToken: HotKeyManager.RegistrationToken?
  @Namespace private var heroNamespace
  @State private var isDetailViewPresented = false

  private var currentUserMemos: [Memo] {
    memoStore.memos
  }

  private let columns = [
    GridItem(.adaptive(minimum: 180, maximum: 300), spacing: 16),
  ]

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
        // Grid View
        VStack(alignment: .leading, spacing: 16) {
          // Date Header
          HStack {
            Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
              .font(.title)

            Spacer()
          }
          .padding(.horizontal)

          if currentUserMemos.isEmpty {
            ContentUnavailableView(
              "No Memos",
              systemImage: "square.text.square",
              description: Text("Tap the + button to create a memo"),
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            ScrollView {
              LazyVGrid(columns: columns, spacing: 16) {
                ForEach(currentUserMemos) { memo in
                  MemoGridItem(memo: memo)
                    .matchedGeometryEffect(id: memo.id, in: heroNamespace)
                    .onTapGesture {
                      withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedMemo = memo
                        isDetailViewPresented = true
                      }
                    }
                }
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 20)
            }
          }
        }
        .task {
          // Load local memos when view appears
          await memoStore.load()
        }
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
    .onAppear {
      registerESCHandler()
    }
    .onDisappear {
      unregisterESCHandler()
    }
    .onChange(of: isDetailViewPresented) { _, isPresented in
      if isPresented {
        registerESCHandler()
      } else {
        // Detail closed, re-register to ensure we are top?
        // Actually MemoView's ESC handler is for detail dismissal.
        // If detail is NOT presented, maybe we don't need ESC?
        // Or keep it to ensure it does nothing or propagates (HotKeyManager doesn't propagate automatically).
        // Let's keep it simple: Register on appear, handle logic inside.
        // Wait, stack behavior: If I navigate deeply, I want THIS view to handle ESC.
        // If I open detail, I want ESC to close detail.
      }
    }
  }

  private func registerESCHandler() {
    // Avoid double registration
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

  private func addNewMemo() {
    memoStore.add(content: "")

    Task {
      try? await Task.sleep(for: .seconds(0.1))
      if let newMemo = currentUserMemos.first {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
          selectedMemo = newMemo
          isDetailViewPresented = true
        }
      }
    }
  }

  private func dismissDetail() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      selectedMemo = nil
      isDetailViewPresented = false
    }
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
}

#Preview {
  // Note: PrivateMemoStore does not have a static preview yet, need to mock or provide one if needed
  // For now, assuming environment injection will be handled in app preview or ignored here
  MemoView()
}
