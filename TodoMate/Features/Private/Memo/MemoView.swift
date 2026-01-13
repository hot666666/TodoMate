//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct MemoView: View {
  @Environment(PrivateMemoStore.self) private var memoStore

  @State private var selectedMemo: Memo?
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
    .onKeyPress(.escape) {
      if isDetailViewPresented {
        dismissDetail()
        return .handled
      }
      return .ignored
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
