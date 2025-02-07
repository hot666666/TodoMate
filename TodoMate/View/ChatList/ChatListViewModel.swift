//
//  ChatListViewModel.swift
//  TodoMate
//
//  Created by hs on 9/2/24.
//

import SwiftUI

@Observable
class ChatListViewModel {
    private let container: DIContainer
    
    var chats: [Chat] = []
    var isUploadingImage: Bool = false
    var isTargeted: Bool = false
    
    private var task: Task<Void, Never>?
    
    init(container: DIContainer) {
        self.container = container
        Task {
            await fetch()
            setupRealtimeUpdates()
        }
    }
    
    deinit {
        task?.cancel()
        container.chatService.cancelTask()
    }
    
    private func setupRealtimeUpdates() {
        task = Task {
            for await change in container.chatService.observeChatChanges() {
                print("[Observed Chat change in FirebaseFirestore] - ", change)
                await handleDatabaseChange(change)
            }
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
            /// Signature가 같다면, 내가 입력 중이던 요소라 업데이트가 따로 필요 없다
            guard (chat.sign != Const.Signature) else { return }
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

extension ChatListViewModel {
    func setIsTargeted(_ isTargeted: Bool) {
        self.isTargeted = isTargeted
    }
    
    @MainActor
    func fetch() async {
        chats = await container.chatService.fetch()
    }
    
    func create(with url: String? = nil) {
        container.chatService.create(with: url)
    }
    
    func update(_ chat: Chat) {
        container.chatService.update(chat)
    }
    
    func remove(_ chat: Chat) {
        container.chatService.remove(chat)
    }
    
    @MainActor
    func uploadImage(data: Data?) -> Bool {
        guard
            let data = data,
            let image = NSImage(data: data), image.isValid else {
            return false
        }
        
        Task {
            isUploadingImage = true
            let url = await container.imageUploadService.upload(data: data)
            create(with: url)
            isUploadingImage = false
        }
        
        return true
    }
}
