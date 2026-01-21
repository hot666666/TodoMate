//
//  TodoColumnView.swift
//  TodoMate
//
//  Created by agent on 1/19/26.
//

import SwiftUI
import TodoMateDomain

/// 상태별 Todo 컬럼 (DayTodoList)
struct TodoColumnView<Content: View>: View {
  // MARK: - Types

  enum HeaderStyle {
    case dot(color: Color)
    case icon(systemName: String, color: Color)
  }

  // MARK: - Properties

  let title: String
  let count: Int
  let headerStyle: HeaderStyle
  @ViewBuilder let content: Content

  // MARK: - Init (convenience for dot style)

  init(title: String, count: Int, color: Color, @ViewBuilder content: () -> Content) {
    self.title = title
    self.count = count
    headerStyle = .dot(color: color)
    self.content = content()
  }

  // MARK: - Init (with explicit style)

  init(title: String, count: Int, headerStyle: HeaderStyle, @ViewBuilder content: () -> Content) {
    self.title = title
    self.count = count
    self.headerStyle = headerStyle
    self.content = content()
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      columnHeader
      content
    }
    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1),
    )
  }

  // MARK: - Column Header

  private var columnHeader: some View {
    HStack {
      HStack(spacing: 8) {
        headerIndicator
        Text(title)
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.primary)
      }

      Spacer()

      Text("\(count)")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.white.opacity(0.02))
  }

  @ViewBuilder
  private var headerIndicator: some View {
    switch headerStyle {
    case let .dot(color):
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
    case let .icon(systemName, color):
      Image(systemName: systemName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(color)
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    HStack {
      TodoColumnView(
        title: "Todo", count: 3, headerStyle: .icon(systemName: "circle", color: .blue),
      ) {
        Text("Icon style")
          .padding()
      }
      .frame(width: 200, height: 300)

      TodoColumnView(title: "Complete", count: 5, color: .green) {
        Text("Dot style")
          .padding()
      }
      .frame(width: 200, height: 300)
    }
  }
  .frame(width: 500, height: 400)
}
