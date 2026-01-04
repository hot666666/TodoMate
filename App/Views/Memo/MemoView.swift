//
//  MemoView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct MemoView: View {
  @State private var memos: [Memo] = [
    Memo(content: "Design System Ideas\n- Typography\n- Colors\n- Spacing"),
    Memo(content: "Groceries\n- Milk\n- Eggs\n- Bread"),
    Memo(content: "Meeting Notes\n- Discuss Q1 Goals\n- Review budget"),
    Memo(content: "Ideas for new features\n- Memo View\n- Calendar"),
    Memo(content: "Random Thoughts\n- Why is the sky blue?\n- Cats are cool"),
    Memo(content: "Todo for later\n- Fix bugs\n- Refactor code"),
    Memo(
      content:
      "Long text example to see how it looks in the grid view. This should truncated or handled gracefully.",
    ),
  ]

  @State private var selectedMemo: Memo?
  @Namespace private var heroNamespace
  @State private var isDetailViewPresented = false

  private let columns = [
    GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16),
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
          onDismiss: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
              self.selectedMemo = nil
              isDetailViewPresented = false
            }
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

          ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
              ForEach(memos) { memo in
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
        .padding(.top)
      }
    }
    .toolbar {
      if !isDetailViewPresented {
        ToolbarItem(placement: .primaryAction) {
          Button(action: {
            // Add new memo
            let newMemo = Memo(content: "New Memo")
            memos.insert(newMemo, at: 0)

            Task {
              try? await Task.sleep(for: .seconds(0.1))
              withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedMemo = newMemo
                isDetailViewPresented = true
              }
            }
          }) {
            Image(systemName: "plus")
          }
        }
      }
    }
  }
}

struct MemoGridItem: View {
  let memo: Memo

  var body: some View {
    VStack(alignment: .leading) {
      Text(memo.content)
        .font(.caption)
        .lineLimit(8)
        .multilineTextAlignment(.leading)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .topLeading)

      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(height: 150)
    .cardContainer(cornerRadius: 12)
  }
}

struct MemoDetailView: View {
  let memo: Memo
  var namespace: Namespace.ID
  var onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading) {
      // Toolbar-like header for Detail View
      HStack {
        Button(action: onDismiss) {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
            Text("Back")
          }
          .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .padding()
      .background(.bar)

      ScrollView {
        Text(memo.content)
          .font(.body)
          .padding(24)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .cardContainer(cornerRadius: 0) // Full screen background
    .matchedGeometryEffect(id: memo.id, in: namespace)
  }
}

#Preview {
  MemoView()
}
