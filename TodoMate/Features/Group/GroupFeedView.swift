//
//  GroupFeedView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import PhotosUI
import SwiftUI

struct GroupFeedView: View {
  @State private var viewModel = GroupFeedViewModel()
  @State private var isChatVisible = true
  @State private var chatPanelWidth: CGFloat = 340

  private let minChatWidth: CGFloat = 280
  private let maxChatWidth: CGFloat = 500

  var body: some View {
    HStack(spacing: 0) {
      // Main Content
      VStack(spacing: 0) {
        headerView
        feedContent
      }
      .frame(maxWidth: .infinity)

      // Resizable Chat Panel (trailing)
      if isChatVisible {
        // Resize Handle
        Rectangle()
          .fill(Color.clear)
          .frame(width: 6)
          .contentShape(Rectangle())
          .onHover { hovering in
            if hovering {
              NSCursor.resizeLeftRight.push()
            } else {
              NSCursor.pop()
            }
          }
          .gesture(
            DragGesture()
              .onChanged { value in
                let newWidth = chatPanelWidth - value.translation.width
                chatPanelWidth = min(maxChatWidth, max(minChatWidth, newWidth))
              },
          )

        // Chat Panel
        ChatPanelView(
          viewModel: viewModel,
          onClose: {
            withAnimation(.easeInOut(duration: 0.2)) {
              isChatVisible = false
            }
          },
        )
        .frame(width: chatPanelWidth)
        .transition(.move(edge: .trailing))
      }
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if !isChatVisible {
          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              isChatVisible = true
            }
          } label: {
            Image(systemName: "bubble.left.and.bubble.right.fill")
              .foregroundStyle(.blue)
          }
        }
      }
    }
  }

  // MARK: - Header

  private var headerView: some View {
    HStack {
      HStack(spacing: 12) {
        Image(systemName: "briefcase.fill")
          .foregroundStyle(.secondary)

        Text(viewModel.activeGroup?.name ?? "Group Feed")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text("Group")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.blue)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.blue.opacity(0.1))
          .clipShape(Capsule())
      }

      Spacer()

      HStack(spacing: 16) {
        // User Avatars
        HStack(spacing: -10) {
          ForEach(viewModel.members.prefix(3)) { member in
            AsyncImage(url: URL(string: member.avatarUrl ?? "")) { phase in
              if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
              } else {
                Circle().fill(Color.gray.opacity(0.3))
              }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
          }

          if viewModel.members.count > 3 {
            Text("+\(viewModel.members.count - 3)")
              .font(.caption2)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .frame(width: 32, height: 32)
              .background(Color.gray.opacity(0.1))
              .clipShape(Circle())
          }
        }

        Button {
          // More actions
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 20))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
  }

  // MARK: - Feed Content

  private var feedContent: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        ForEach(viewModel.members) { member in
          GroupMemberSection(
            user: member,
            todos: viewModel.memberTodos[member.id ?? ""] ?? [],
          )
        }
      }
      .padding(24)
    }
  }
}

// MARK: - Group Member Section

private struct GroupMemberSection: View {
  let user: ViewUser
  let todos: [ViewTodo]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(spacing: 12) {
        AsyncImage(url: URL(string: user.avatarUrl ?? "")) { phase in
          if let image = phase.image {
            image.resizable().aspectRatio(contentMode: .fill)
          } else {
            Circle().fill(Color.gray.opacity(0.3))
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(user.displayName)
            .font(.subheadline)
            .fontWeight(.semibold)

          Text("Updated 2m ago")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // Todos
      if todos.isEmpty {
        HStack(spacing: 12) {
          Image(systemName: "circle.dashed")
            .font(.system(size: 20))
            .foregroundStyle(.tertiary)
          Text("No tasks shared")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(todos) { todo in
            SharedTodoRow(todo: todo)
          }
        }
      }
    }
    .padding(.bottom, 16)
  }
}

// MARK: - Chat Panel View

private struct ChatPanelView: View {
  @Bindable var viewModel: GroupFeedViewModel
  var onClose: () -> Void

  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImageData: Data?

  var body: some View {
    VStack(spacing: 0) {
      // Messages
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            Text("TODAY")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundStyle(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.secondary.opacity(0.1))
              .clipShape(Capsule())
              .padding(.top, 10)

            ForEach(viewModel.chatMessages) { message in
              ChatMessageBubble(
                message: message,
                isMe: message.senderId == "user_3",
                user: viewModel.getMember(byId: message.senderId),
              )
              .id(message.id)
            }
          }
          .padding(16)
        }
        .onChange(of: viewModel.chatMessages) {
          if let lastId = viewModel.chatMessages.last?.id {
            withAnimation {
              proxy.scrollTo(lastId, anchor: .bottom)
            }
          }
        }
      }

      // Input
      chatInput
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        chatHeader
      }
    }
    .background(.ultraThinMaterial)
  }

  private var chatHeader: some View {
    Button(action: onClose) {
      Image(systemName: "arrow.right.to.line")
    }
  }

  private var chatInput: some View {
    VStack(spacing: 0) {
      if let data = selectedImageData, let nsImage = NSImage(data: data) {
        HStack {
          Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
              Button {
                selectedImageData = nil
                selectedItem = nil
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.system(size: 14))
                  .foregroundStyle(.white, .gray)
              }
              .offset(x: 4, y: -4),
              alignment: .topTrailing,
            )
          Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
      }

      HStack(spacing: 8) {
        // Photo picker
        PhotosPicker(selection: $selectedItem, matching: .images) {
          Image(systemName: "photo")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onChange(of: selectedItem) {
          Task {
            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
              selectedImageData = data
            }
          }
        }

        TextField("Write a message...", text: $viewModel.chatInputText)
          .textFieldStyle(.plain)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(nsColor: .textBackgroundColor))
          .clipShape(RoundedRectangle(cornerRadius: 8))

        // Send button
        Button {
          viewModel.sendMessage(text: viewModel.chatInputText, image: selectedImageData)
          selectedImageData = nil
          selectedItem = nil
        } label: {
          Image(systemName: "paperplane.fill")
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Color.blue)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.chatInputText.isEmpty && selectedImageData == nil)
      }
      .padding(12)
    }
    .background(Color(nsColor: .separatorColor).opacity(0.05))
  }
}

#Preview {
  GroupFeedView()
}
