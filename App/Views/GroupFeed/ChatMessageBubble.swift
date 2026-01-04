//
//  ChatMessageBubble.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct ChatMessageBubble: View {
  let message: ChatMessage
  let isMe: Bool
  let user: User?

  var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      if isMe {
        Spacer()
      } else {
        // Avatar for others
        AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { phase in
          if let image = phase.image {
            image.resizable().aspectRatio(contentMode: .fill)
          } else {
            Color.gray.opacity(0.3)
          }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
      }

      VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
        if !isMe {
          Text(user?.displayName ?? "Unknown")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
        }

        VStack(alignment: isMe ? .trailing : .leading, spacing: 0) {
          if let imageUrl = message.imageUrl {
            // Image Handling
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
                    let nsImage = NSImage(data: localData)
          {
            // Local Image Preview
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
              .foregroundStyle(isMe ? .primary : .primary) // Adjust colors based on bg
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
          }
        }
        .background(bubbleBackground)
        .clipShape(bubbleShape)
        .shadow(color: .black.opacity(isMe ? 0.05 : 0.02), radius: 2, x: 0, y: 1)
      }

      if !isMe {
        Spacer()
      } else {
        // Avatar for me or nothing? Design usually puts avatar on right for "me" or just bubble.
        // HTML reference shows Avatar on right for "Me".
        AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { phase in
          if let image = phase.image {
            image.resizable().aspectRatio(contentMode: .fill)
          } else {
            Color.gray.opacity(0.3)
          }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
      }
    }
  }

  var bubbleBackground: some View {
    ZStack { // Changed Group to ZStack or just remove wrapper if not needed. Group is fine, but maybe type inference issue.
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
    RoundedRectangle(cornerRadius: 16)
      .corners(
        topLeft: 16,
        topRight: 16,
        bottomLeft: isMe ? 16 : 4,
        bottomRight: isMe ? 4 : 16,
      )
  }
}

// Helper for custom corner rounding
extension View {
  func corners(topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat)
    -> some Shape
  {
    CustomRoundedRectangle(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    )
  }
}

struct CustomRoundedRectangle: Shape {
  var topLeft: CGFloat
  var topRight: CGFloat
  var bottomLeft: CGFloat
  var bottomRight: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let w = rect.size.width
    let h = rect.size.height

    // Top left
    path.move(to: CGPoint(x: topLeft, y: 0))

    // Top right
    path.addLine(to: CGPoint(x: w - topRight, y: 0))
    path.addArc(
      center: CGPoint(x: w - topRight, y: topRight), radius: topRight,
      startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false,
    )

    // Bottom right
    path.addLine(to: CGPoint(x: w, y: h - bottomRight))
    path.addArc(
      center: CGPoint(x: w - bottomRight, y: h - bottomRight), radius: bottomRight,
      startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false,
    )

    // Bottom left
    path.addLine(to: CGPoint(x: bottomLeft, y: h))
    path.addArc(
      center: CGPoint(x: bottomLeft, y: h - bottomLeft), radius: bottomLeft,
      startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false,
    )

    // Top left
    path.addLine(to: CGPoint(x: 0, y: topLeft))
    path.addArc(
      center: CGPoint(x: topLeft, y: topLeft), radius: topLeft,
      startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false,
    )

    return path
  }
}
