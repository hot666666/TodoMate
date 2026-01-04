//
//  GroupMemberCard.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct GroupMemberCard: View {
  let user: User
  let todos: [Todo]

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack(spacing: 12) {
        AsyncImage(url: URL(string: user.avatarUrl ?? "")) { phase in
          if let image = phase.image {
            image.resizable().aspectRatio(contentMode: .fill)
          } else {
            Color.gray.opacity(0.3)
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))

        VStack(alignment: .leading, spacing: 2) {
          Text(user.displayName)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          Text("Updated 2m ago")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }
      .padding(.bottom, 16)

      // Todos List
      VStack(alignment: .leading, spacing: 0) {
        if todos.isEmpty {
          Text("No tasks shared yet.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .italic()
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
          ForEach(todos) { todo in
            SharedTodoRow(todo: todo)
            if todo.id != todos.last?.id {
              Divider()
                .background(Color.white.opacity(0.3))
            }
          }
        }
      }
      .cardContainer(cornerRadius: 12, shadowRadius: 4, shadowY: 2)

      // Footer
      HStack {
        Spacer()
        Button {
          // Comments action
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "bubble.left.and.bubble.right")
              .font(.system(size: 14))
            Text("Comments")
          }
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
      }
    }
    .padding(20)
    .cardContainer(cornerRadius: 20)
  }
}
