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

  @Namespace private var namespace
  @State private var selectedMemo: Memo?

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

      VStack(alignment: .leading, spacing: 16) {
        // Date Header
        Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
          .font(.title2)
          .fontWeight(.semibold)
          .padding(.horizontal, 20)

        // Grid View
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
                MemoGridItem(memo: memo, namespace: namespace)
                  .onTapGesture {
                    withAnimation(.spring(duration: 0.4)) {
                      selectedMemo = memo
                    }
                  }
              }
            }
            .padding(.horizontal, 20)
          }
        }
      }
      .padding(.top)

      // Detail Overlay
      if let memo = selectedMemo {
        Color.black.opacity(0.3)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(duration: 0.4)) {
              selectedMemo = nil
            }
          }

        MemoDetailView(
          memo: Binding(
            get: { memo },
            set: { newValue in
              selectedMemo = newValue
            },
          ),
          namespace: namespace,
        ) {
          withAnimation(.spring(duration: 0.4)) {
            selectedMemo = nil
          }
        }
        .frame(maxWidth: 600, maxHeight: 500)
        .padding(40)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          addNewMemo()
        } label: {
          Image(systemName: "plus")
        }
      }
    }
    .accessibilityIdentifier("memoView")
  }

  private func addNewMemo() {
    memoStore.add(content: "", currentUserId: sessionStore.userId)
    // Select the newly created memo (it's inserted at index 0)
    if let newMemo = currentUserMemos.first {
      withAnimation(.spring(duration: 0.4)) {
        selectedMemo = newMemo
      }
    }
  }
}

#Preview {
  MemoView()
    .environment(MemoStore.preview)
    .environment(SessionStore.preview)
}
