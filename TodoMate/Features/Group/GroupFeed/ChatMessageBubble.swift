//
//  ChatMessageBubble.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI
import TodoMateDomain

struct ChatMessageBubble: View {
  let message: ViewGroupMessage
  let isMe: Bool
  let user: User?

  var body: some View {
    if isMe {
      // 내 메시지: 말풍선만 표시 (아바타 없음)
      VStack(alignment: .trailing, spacing: 0) {
        bubbleContent
      }
    } else {
      // 상대방 메시지: 이름 + 말풍선
      VStack(alignment: .leading, spacing: 4) {
        if let displayName = user?.displayName {
          Text(displayName)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.leading, 2)
        }

        bubbleContent
      }
    }
  }

  private var bubbleContent: some View {
    VStack(alignment: isMe ? .trailing : .leading, spacing: 0) {
      if let imageUrl = message.imageUrl {
        AsyncImage(url: URL(string: imageUrl)) { phase in
          if let image = phase.image {
            image.resizable().aspectRatio(contentMode: .fill)
          } else {
            ProgressView()
              .frame(width: 150, height: 100)
              .background(Color.gray.opacity(0.1))
          }
        }
        .frame(maxWidth: 200, maxHeight: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, message.text != nil ? 8 : 0)
      } else if let localData = message.localImageData,
                let nsImage = NSImage(data: localData) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(maxWidth: 200, maxHeight: 200)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .padding(.bottom, message.text != nil ? 8 : 0)
      }

      if let text = message.text, !text.isEmpty {
        Text(text)
          .font(.system(size: 14))
          .foregroundStyle(.primary)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
      }
    }
    .background(bubbleBackground)
    .clipShape(bubbleShape)
    .shadow(color: .black.opacity(isMe ? 0.05 : 0.02), radius: 2, x: 0, y: 1)
  }

  var bubbleBackground: some View {
    ZStack {
      if isMe {
        Color.blue.opacity(0.1)
          .background(.ultraThinMaterial)
      } else {
        Color.white.opacity(0.6)
          .background(.ultraThinMaterial)
      }
    }
  }

  var bubbleShape: some Shape {
    CustomRoundedRectangle(
      topLeft: 16,
      topRight: 16,
      bottomLeft: isMe ? 16 : 4,
      bottomRight: isMe ? 4 : 16,
    )
  }
}

#Preview {
  VStack(spacing: 16) {
    ChatMessageBubble(
      message: ViewGroupMessage(senderId: "user_1", text: "Hello!"),
      isMe: false,
      user: User(id: "user_1", displayName: "Sarah"),
    )
    ChatMessageBubble(
      message: ViewGroupMessage(senderId: "user_3", text: "Hi there!"),
      isMe: true,
      user: User(id: "user_3", displayName: "Me"),
    )
  }
  .padding()
}
