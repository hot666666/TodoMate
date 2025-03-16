//
//  MessageView.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//

import MarkdownUI
import SwiftUI

struct MessageView: View {
  @FocusState private var focusedMessageID: String?

  @State var messageStore: MessageStore
  let userInfo: AuthenticatedUser

  private func createMessage() {
    try? messageStore.createMessage(lastModifiedUser: userInfo.uid)
  }

  private func onAppear() async {
    try? await messageStore.readMessages()
    await messageStore.observeMessageChanges()
  }
}

extension MessageView {
  var body: some View {
    content
      .background(Color.clear)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          addButton
        }
      }
      .onTapGesture {
        focusedMessageID = nil
      }
      .environment(messageStore)
      .task {
        await onAppear()
      }
  }

  @ViewBuilder
  private var content: some View {
    if messageStore.messages.isEmpty {
      emptyView
    } else {
      ScrollView {
        ForEach(messageStore.messages) { message in
          MessageContent(message: message, userInfo: userInfo, focusedId: $focusedMessageID)
            .disabled(message.lastModifiedUser != userInfo.uid)
        }
        .padding()
      }
    }
  }

  private var emptyView: some View {
    Text("메모가 존재하지 않습니다.")
      .frame(maxHeight: .infinity, alignment: .center)
  }

  private var addButton: some View {
    Button {
      createMessage()
    } label: {
      Image(systemName: "plus")
    }
  }
}

private struct MessageContent: View {
  @Environment(MessageStore.self) private var messageStore
  private let userInfo: AuthenticatedUser

  @Bindable private var message: MessageModel
  @State private var localContent: String

  @FocusState.Binding private var focusedId: String?

  init(message: MessageModel, userInfo: AuthenticatedUser, focusedId: FocusState<String?>.Binding) {
    self.message = message
    self.userInfo = userInfo
    _focusedId = focusedId
    _localContent = State(initialValue: message.content)
  }

  enum Mode {
    case edit, preview

    var toggle: Mode {
      (self == .edit) ? .preview : .edit
    }
  }

  @State private var mode: Mode = .preview

  private var messageCaption: String {
    switch mode {
    case .edit:
      return "수정 중"
    case .preview:
      var caption: String = message.lastModifiedAt.toYYYYMMDDString()
      if message.lastModifiedUser == userInfo.uid {
        caption += " (나)"
      }
      return caption
    }
  }

  private func updateMessage() {
    guard localContent != message.content else { return }
    try? messageStore.updateMessage(
      message,
      newContent: localContent,
      lastModifiedUser: userInfo.uid
    )
  }

  private func deleteMessage() {
    try? messageStore.deleteMessage(message)
  }

  var body: some View {
    VStack {
      contentView
        .padding(10)
    }
    .contentShape(.rect)
    .onTapGesture {
      mode = mode.toggle
      focusedId = nil
      if mode == .edit {
        focusedId = message.id
      }
    }
    .onChange(of: focusedId) { old, new in
      if new != message.id {
        mode = .preview
        if old == message.id {
          updateMessage()
        }
      }
    }
    .contextMenu {
      Button("삭제") {
        deleteMessage()
      }
    }
    .background(.ultraThickMaterial)
    .shadow(color: .black.opacity(0.3), radius: 7, x: 0, y: 0)
  }

  @ViewBuilder
  private var contentView: some View {
    switch mode {
    case .edit:
      editView
    case .preview:
      markdownView
    }
    contentFooter
  }

  private var contentFooter: some View {
    Text(messageCaption)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .font(.caption)
      .foregroundColor(.white)
      .opacity(0.4)
  }

  private var markdownView: some View {
    HStack {
      Markdown(localContent.isEmpty ? "클릭하여 입력하세요." : localContent)
        .opacity(localContent.isEmpty ? 0.5 : 1)
        .padding(.leading, 5)
        .background(Color.clear)
      Spacer()
    }
  }

  private var editView: some View {
    TextEditor(text: $localContent)
      .scrollDisabled(true)
      .fixedSize(horizontal: false, vertical: true)
      .scrollIndicators(.never)
      .scrollContentBackground(.hidden)
      .font(.system(size: 13))
      .padding(.trailing)
      .focused($focusedId, equals: message.id)
  }
}

#Preview {
  MessageView(messageStore: MessageStore.stub, userInfo: AuthenticatedUser.stub)
    .frame(width: 450, height: 450)
}
