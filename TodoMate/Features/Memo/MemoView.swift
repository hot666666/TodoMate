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

  @State private var isEditing = false
  @State private var editedContent = ""

  private var currentMemo: Memo? {
    memoStore.memos[sessionStore.userId] ?? nil
  }

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

        if isEditing {
          // Edit Mode
          VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $editedContent)
              .font(.body)
              .scrollContentBackground(.hidden)
              .padding(16)
              .background(.regularMaterial)
              .clipShape(.rect(cornerRadius: 12))
              .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
              Spacer()
              Button("Cancel") {
                isEditing = false
                editedContent = currentMemo?.content ?? ""
              }
              .buttonStyle(.bordered)

              Button("Save") {
                memoStore.save(editedContent, currentUserId: sessionStore.userId)
                isEditing = false
              }
              .buttonStyle(.borderedProminent)
            }
          }
          .padding(.horizontal, 20)
        } else {
          // View Mode
          ScrollView {
            VStack(alignment: .leading, spacing: 16) {
              if let memo = currentMemo, !memo.isEmpty {
                Text(memo.content)
                  .font(.body)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(24)
                  .cardContainer(cornerRadius: 12)
                  .onTapGesture {
                    editedContent = memo.content
                    isEditing = true
                  }
              } else {
                ContentUnavailableView(
                  "No Memo",
                  systemImage: "square.text.square",
                  description: Text("Tap the + button to create a memo"),
                )
                .frame(maxWidth: .infinity)
                .padding(40)
              }
            }
            .padding(.horizontal, 20)
          }
        }
      }
      .padding(.top)
    }
    .toolbar {
      if !isEditing {
        ToolbarItem(placement: .primaryAction) {
          Button {
            editedContent = currentMemo?.content ?? ""
            isEditing = true
          } label: {
            Image(systemName: currentMemo == nil ? "plus" : "pencil")
          }
        }
      }
    }
    .accessibilityIdentifier("memoView")
  }
}

#Preview {
  MemoView()
    .environment(MemoStore.preview)
    .environment(SessionStore.preview)
}
