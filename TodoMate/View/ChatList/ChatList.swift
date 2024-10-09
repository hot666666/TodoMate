//
//  ChatView.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import SwiftUI

struct ChatList: View {
    @Environment(AppState.self) private var appState: AppState
    @State var viewModel: ChatListViewModel
    @FocusState private var focusedId: String?
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { clearFocus() }
            
                VStack(spacing: 10) {
                    ForEach(viewModel.chats) { chat in
                        ChatItem(viewModel: viewModel, item: chat, focusedId: $focusedId)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.remove(chat)
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
                .background(viewModel.isTargeted ? Color.blue.opacity(0.3) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(viewModel.isTargeted ? Color.blue : Color.clear, lineWidth: 2)
                        )
                .dropDestination(for: Data.self) { droppedItems, _ in
                    viewModel.uploadImage(data: droppedItems.first)
                } isTargeted: { viewModel.setIsTargeted($0) }
                .padding(5)
                .padding(.horizontal, 5)
            
            if viewModel.isUploadingImage {
                Color.gray.opacity(0.2)
                ProgressView()
            }
        }
        .onChange(of: appState.isSelectedTodo) { _, newValue in
            if newValue {
                clearFocus()
            }
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            viewModel.create()
        }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
    }
}
 
extension ChatList {
    private func clearFocus() {
        focusedId = nil
    }
}
