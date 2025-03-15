//
//  MessageView.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//

import SwiftUI
import MarkdownUI

struct MessageView: View {
  @State var messageStore: MessageStore
  let userInfo: AuthenticatedUser
  
  var body: some View {
    ScrollView {
      ForEach(messageStore.messages) { message in
        MessageContent(message: message, userInfo: userInfo)
      }
      .padding()
    }
    .overlay(alignment: .topTrailing, content: {
      Button {
        do {
          try messageStore.createMessage(lastModifiedUser: userInfo.uid)
        } catch {
          print(error)
        }
      } label: {
        Image(systemName: "plus")
          .font(.title)
      }
      .hoverButtonStyle()
      .padding()
      .offset(y: -50)
    })
    .environment(messageStore)
    .task {
      try? await messageStore.readMessages()
      await messageStore.observeMessageChanges()
    }
  }
}

fileprivate struct MessageContent: View {
  @Environment(MessageStore.self) private var messageStore
  private let userInfo: AuthenticatedUser
  
  @Bindable var message: MessageModel
  @State private var localContent: String
  
  init(message: MessageModel, userInfo: AuthenticatedUser) {
    self.message = message
    self.userInfo = userInfo
    self._localContent = State(initialValue: message.content)
  }
  
  private var isMine: Bool {
    message.lastModifiedUser == userInfo.uid
  }
  
  private var messageCaption: String {
    var caption: String = message.lastModifiedAt.toYYYYMMDDString()
    if isMine {
      caption += " (나)"
    }
    return caption
  }
  
  @FocusState private var isFocused: Bool
  
  enum Mode: String {
    case edit = "확인"
    case preview = "수정"
  }
  @State private var mode: Mode = .preview
  private var toggleButtonTitle: String {
    if mode == .edit && localContent.isEmpty {
      return "삭제"
    }
    return mode.rawValue
  }
  
  @State private var inactivityTask: Task<Void, Never>? = nil
  
  private func toggleMode() {
    mode = (mode == .edit) ? .preview : .edit
    if mode == .edit {
      startInactivityTask()
      isFocused = true
    } else {
      cancelInactivityTask()
    }
  }
  
  // 입력 감지 시 타이머 리셋
  private func resetInactivityTask() {
    cancelInactivityTask()
    if mode == .edit {
      startInactivityTask()
    }
  }
  
  // 3초 후 자동으로 preview 모드로 전환
  private func startInactivityTask() {
    inactivityTask = Task { @MainActor in
      do {
        try await Task.sleep(nanoseconds: 3_000_000_000)
      } catch {
        return
      }
      
      if mode == .edit {
        toggleMode()
      }
    }
  }
  
  // 타이머 취소
  private func cancelInactivityTask() {
    inactivityTask?.cancel()
    inactivityTask = nil
  }
}

extension MessageContent {
  var body: some View {
    VStack {
      contentView
        .padding(10)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      if mode == .preview {
        toggleMode()
      }
    }
    .overlay(alignment: .topTrailing) {
      toggleButton
    }
    .background(.ultraThickMaterial)
    .shadow(color: .black.opacity(0.2), radius: 7, x: 0, y: 0)
    .onChange(of: isFocused) { old, new in
      if old == true && new == false {
        print("변경 발생")
        
        // 삭제 조건 확인
        if localContent.isEmpty {
          try? messageStore.deleteMessage(message)
          return
        }
        
        // 업데이트의 조건 확인
        if message.content == localContent && message.lastModifiedUser == userInfo.uid {
          print("no change")
          return
        }
        
        // 업데이트 수행
        try? messageStore.updateMessage(message, newContent: localContent, lastModifiedUser: userInfo.uid)
      }
    }
  }
  
  @ViewBuilder
  private var contentView: some View {
    switch mode {
    case .edit:
      editView
    case .preview:
      markdownView
    }
  }
  
  private var markdownView: some View {
    VStack {
      HStack {
        Markdown(localContent.isEmpty ? "클릭하여 입력하세요." : localContent)
          .opacity(localContent.isEmpty ? 0.5 : 1)
          .padding(.leading, 5)
          .background(Color.clear)
        Spacer()
      }
      Text(messageCaption)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .font(.caption)
        .foregroundColor(.white)
        .opacity(0.3)
    }
    .onTapGesture {
      toggleMode()
    }
  }
  
  private var editView: some View {
    EditView(text: $localContent)
      .font(.system(size: 13))
      .focused($isFocused)
      .padding(.trailing)
      .onChange(of: localContent) { _, _ in
        resetInactivityTask()
      }
  }
  
  private var toggleButton: some View {
    Button(toggleButtonTitle) {
      if isMine {
        toggleMode()
      }
    }
    .hoverButtonStyle3()
  }
}

fileprivate struct EditView: View {
  @Binding var text: String
  
  var body: some View {
    TextEditor(text: $text)
      .scrollDisabled(true)
      .fixedSize(horizontal: false, vertical: true)
      .scrollIndicators(.never)
      .scrollContentBackground(.hidden)
  }
}

#Preview {
  MessageView(messageStore: MessageStore.stub, userInfo: AuthenticatedUser.stub)
    .frame(width: 450, height: 450)
}
