//
//  TodoCardView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct TodoCardView: View {
  let todo: Todo
  // In a real app, we'd fetch the user profile. For now, we mock the avatar.
  let showEditButton: Bool

  var cardColor: Color {
    // Map tags or status to color. For now, random or fixed based on context.
    // In design, "Design System" has purple accent.
    if todo.tags.contains("Design System") { return DesignSystem.Colors.accentPurple }
    if todo.tags.contains("Frontend") { return DesignSystem.Colors.accentCyan }
    if todo.tags.contains("Urgent") { return .red }
    if todo.tags.contains("Research") { return DesignSystem.Colors.accentIndigo }
    return .gray
  }

  var body: some View {
    ZStack(alignment: .leading) {
      // Background
      RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge)
        .fill(Color(nsColor: .controlBackgroundColor)) // Adaptive surface
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
          RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge)
            .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1),
        )

      // Left colored stripe
      HStack(spacing: 0) {
        Rectangle()
          .fill(cardColor.opacity(0.5))
          .frame(width: 4)

        VStack(alignment: .leading, spacing: 12) {
          // Top Row: Tag/Context + Edit Button
          HStack(alignment: .top) {
            if let firstTag = todo.tags.first {
              StatusBadge(
                title: firstTag,
                color: cardColor,
                icon: nil,
              )
            } else {
              Spacer()
            }

            Spacer()

            if showEditButton {
              Button {
                // Edit action
              } label: {
                Image(systemName: "pencil")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
              .opacity(0.5) // Hover effect would be handled by generic hover in macOS
            }
          }

          // Content
          VStack(alignment: .leading, spacing: 4) {
            Text(todo.content)
              .font(.body)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)
              .lineLimit(2)

            if !todo.detail.isEmpty {
              Text(todo.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
          }

          // Footer: Date + Avatar
          HStack {
            HStack(spacing: 4) {
              Image(systemName: "calendar")
              Text(todo.date.formatted(.dateTime.month().day()))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Spacer()

            // Avatar Stack (Mock)
            HStack(spacing: -8) {
              Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                  Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.gray),
                )
                .clipShape(Circle())
                .overlay(
                  Circle().stroke(
                    Color(nsColor: .windowBackgroundColor), lineWidth: 2,
                  ),
                )
            }
          }
        }
        .padding(12)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge))
    .contentShape(Rectangle()) // Make entire card tappable
  }
}

#Preview {
  ZStack {
    Color(nsColor: .windowBackgroundColor)
      .ignoresSafeArea()

    HStack {
      TodoCardView(
        todo: Todo(
          groupId: nil,
          owner: "user1",
          content: "Define Liquid Glass components",
          status: .todo,
          detail:
          "Create standard blurred backgrounds and border radius tokens for the new macOS feel.",
          date: .now,
          tags: ["Design System"],
        ),
        showEditButton: true,
      )
      .frame(width: 280)

      TodoCardView(
        todo: Todo(
          groupId: nil,
          owner: "user1",
          content: "Fix sidebar navigation bug",
          status: .todo,
          detail: "Dropdown menus are not closing when clicking outside.",
          date: .now,
          tags: ["Urgent"],
        ),
        showEditButton: true,
      )
      .frame(width: 280)
    }
    .padding()
  }
}
