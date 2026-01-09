//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct MemoView: View {
  @Environment(MemoStore.self) private var memoStore
  @Environment(SessionStore.self) private var sessionStore

  @State private var selectedMemo: Memo?
  @Namespace private var heroNamespace
  @State private var isDetailViewPresented = false

  private var currentUserMemos: [Memo] {
    memoStore.memos[sessionStore.userId] ?? []
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
          Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.horizontal, 20)

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
        .padding(.top)
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
        }
      }
    }
    .accessibilityIdentifier("memoView")
  }

  private func addNewMemo() {
    memoStore.add(content: "", currentUserId: sessionStore.userId)

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
      memoStore.update(updatedMemo, currentUserId: sessionStore.userId)
    }
  }

  private func deleteMemo(_ memo: Memo) {
    Task {
      await memoStore.delete(memo, currentUserId: sessionStore.userId)
      dismissDetail()
    }
  }
}

#Preview {
  MemoView()
    .environment(MemoStore.preview)
    .environment(SessionStore.preview)
}
