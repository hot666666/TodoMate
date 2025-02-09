//
//  ChatBoardViewModel.swift
//  TodoMate
//
//  Created by hs on 1/22/25.
//

import SwiftUI

@Observable
class ChatBoardViewModel {
    private let chatService: ChatServiceType
    private let chatStreamProvider: ChatStreamProviderType
    private let userInfo: AuthenticatedUser
    
    var chats: [Chat] = []
    
    init(container: DIContainer, userInfo: AuthenticatedUser) {
        self.chatService = container.chatService
        self.chatStreamProvider = container.chatStreamProvider
        self.userInfo = userInfo
    }
}
extension ChatBoardViewModel {
    func observeChanges() async {
        for await change in chatStreamProvider.createChatStream() {
            print("[Observed Chat change in FirebaseFirestore] - ", change)
            await handleDatabaseChange(change)
        }
    }
    
    @MainActor
    private func handleDatabaseChange(_ change: DatabaseChange<Chat>) {
        switch change {
        case .added(let chat):
            if !chats.contains(where: { $0.fid == chat.fid }) {
                chats.append(chat)
            }
        case .modified(let chat):
            /// 내가 입력 중이던 요소는 업데이트 무시
            guard (chat.lastModifiedUser != userInfo.id) else { return }
            if let index = chats.firstIndex(where: { $0.fid == chat.fid }) {
                chats[index] = chat
            }
        case .removed(let chat):
            if let index = chats.firstIndex(where: { $0.fid == chat.fid }) {
                chats.remove(at: index)
            }
        }
    }
}
extension ChatBoardViewModel {
    /// 최초 observeChanges() 시, 모든 데이터를 다 fetch를 수행해서 사용되지 않음
    @MainActor
    func fetchChat() async {
        chats = await chatService.fetch()
    }
    
    func createChat(with url: String? = nil) {
        let chat: Chat = .init(lastModifiedUser: userInfo.id)
        
        /// 이미지 업로드 시
        if let url = url {
            chat.content = url
            chat.isImage = true
        }
        chatService.create(chat)
        
#if PREVIEW
        chat.fid = UUID().uuidString
        chats.append(chat)
#endif
    }
    
    func updateChat(_ chat: Chat) {
        chat.lastModifiedUser = userInfo.id
        chatService.update(chat)
    }
    
    func removeChat(_ chat: Chat) {
        chatService.remove(chat)
        
#if PREVIEW
        if let index = chats.firstIndex(where: { $0.fid == chat.fid }) {
            chats.remove(at: index)
        }
#endif
    }
}
