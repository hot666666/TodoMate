//
//  ChatView.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import SwiftUI

// MARK: - ChatListView
struct ChatListView: View {
    @Environment(ChatManager.self) private var chatManager: ChatManager
    @FocusState private var focusedId: String?
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { clearFocus() }
            
                VStack(spacing: 10) {
                    ForEach(chatManager.chats) { chat in
                        ChatView(item: chat, focusedId: $focusedId)
                            .contextMenu {
                                Button(role: .destructive) {
                                    chatManager.remove(chat)
                                } label: {
                                    Text(Image(systemName: "trash"))+Text(" 삭제")
                                }
                            }
                    }
                    
                    HStack {
                        addButton
                            .padding(.bottom)
                        Spacer()
                    }
                }
                .padding(5)
                .padding(.horizontal, 5)
        }
    }
}
 
extension ChatListView {
    private var addButton: some View {
        Button(action: { chatManager.create() }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
    }
    
    private func clearFocus() {
        focusedId = nil
    }
}

// MARK: - ChatView
fileprivate struct ChatView: View {
    @Environment(ChatManager.self) private var chatManager: ChatManager
    @State private var debouncer = Debouncer(delay: 0.7)
    
    @State private var localContent: String  /// 실제 서버에 업데이트되기 전, 로컬의 입력상태
    var item: Chat
    @FocusState.Binding var focusedId: String?
    
    init(item: Chat, focusedId: FocusState<String?>.Binding) {
        self.item = item
        self._focusedId = focusedId
        self._localContent = State(initialValue: item.content)
    }
    
    var body: some View {
        TextEditor(text: $localContent)
            .textEditorStyle()
            .font(.system(size: 15))
            .focused($focusedId, equals: item.id)
            .shadow(radius: focusedId == item.id ? 5 : 0)
            .onTapGesture { focusedId = item.id }
            .onChange(of: localContent) { _, newValue in
                debouncer.debounce {
                    print("[Updating Chat - \(newValue)]")
                    let updatedChat = item
                    updatedChat.content = newValue
                    updatedChat.sign = Const.Signature  /// 동일 사용자인지 구분하여, 같다면 focused가 풀리지 않음
                    chatManager.update(updatedChat)
                }
            }
    }
}
