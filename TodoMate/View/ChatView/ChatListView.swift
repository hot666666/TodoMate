//
//  ChatView.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import SwiftUI

import Combine

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

struct ChatView: View {
    @Environment(ChatManager.self) private var chatManager: ChatManager
    var item: Chat
    @FocusState.Binding var focusedId: String?
    
    @State private var localContent: String
    @State private var debouncer = Debouncer(delay: 0.7)
    
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
                print(newValue)
                debouncer.debounce {
                    let updatedChat = item
                    updatedChat.content = newValue
                    updatedChat.sign = Const.Signature
                    chatManager.update(updatedChat)
                }
            }
    }
}

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
                        // TODO: - 삭제
//                            .contextMenu {
//                                Button(role: .destructive) {
//                                    chatManager.remove(chat)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
                    }
                    
                    HStack {
                        AddItemButton(action: addNewChat)
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
    private func clearFocus() {
        focusedId = nil
    }
    
    private func addNewChat() {
        chatManager.create()
    }
}

struct AddItemButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
    }
}
