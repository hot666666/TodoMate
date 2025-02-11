//
//  ChatBoardView.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI

// MARK: - ChatBoardView
struct ChatBoardView: View {
    @State private var viewModel: ChatBoardViewModel
    
    init(viewModel: ChatBoardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ExpandableView(
            storageKey: "chatlist",
            header: {
                Text("채팅")
            },
            content: {
                chatListContent
                    .task {
                        await viewModel.observeChanges()
                    }
            }
        )
        .padding(.bottom)
    }
    
    @ViewBuilder
    private var chatListContent: some View {
        ChatListContent(
                chats: viewModel.chats,
                createChat: viewModel.createChat,
                updateChat: viewModel.updateChat,
                removeChat: viewModel.removeChat
            )
        .padding(.horizontal, 10)
    }
}

// MARK: - ChatListContent
fileprivate struct ChatListContent: View {
    @FocusState private var focusedId: String?
    let chats: [Chat]
    let createChat: (String?) -> Void
    let updateChat: (Chat) -> Void
    let removeChat: (Chat) -> Void
    
    var body: some View {
        ZStack {
            clearFocusBackground
            
            chatList
        }
    }
    
    @ViewBuilder
    private var clearFocusBackground: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { focusedId = nil }
    }
    
    @ViewBuilder
    private var chatList: some View {
        VStack(alignment: .leading) {
            ForEach(chats) { chat in
                ChatRow(chat: chat, updateChat: updateChat, removeChat: removeChat)
                    .focused($focusedId, equals: chat.id)
                    .contextMenu {
                        removeButton(chat)
                    }

            }
            
            addButton
            Spacer()
        }
    }
    
    // TODO: - Image onDrop 위치
    @ViewBuilder
    private var addButton: some View {
        HStack{
            Button(action: {
                createChat(nil)
            }) {
                Image(systemName: "plus")
            }
            .hoverButtonStyle()
            .padding(.leading, 25)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func removeButton(_ chat: Chat) -> some View {
        Button {
            removeChat(chat)
        } label: {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
    }
}

// MARK: - ChatRow
fileprivate struct ChatRow: View {
    @State private var isHovered: Bool = false
    
    let chat: Chat
    let updateChat: (Chat) -> Void
    let removeChat: (Chat) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // TODO: - Chat모델에 최근 수정시간 추가하고 해당 값 표시
            // TODO: - Image냐 아니냐 구분해서 표시
            // TODO: - 이미지 드래그 기반 크기 조절
            ellipsis
                .opacity(isHovered ? 1 : 0)
  
            
            ChatInput(
                chat: chat,
                onSubmit: updateChat,
                onDelete: removeChat
            )
        }
        .onHover { isHovered = $0 }
    }
    
    @ViewBuilder
    private var ellipsis: some View {
        Image(systemName: "ellipsis.rectangle")
            .font(.title3)
            .rotationEffect(.degrees(90))
            .foregroundColor(.secondary.opacity(0.3))
            .padding(.top, 2)
    }
}

// MARK: - ChatInput
fileprivate struct ChatInput: View {
    /// 디바운스용 Task(코루틴). 매번 텍스트가 바뀔 때마다 재생성.
    @State private var debouncingTask: Task<Void, Never>? = nil
    private let placeholder: String = "메시지를 입력하세요"
    
    var chat: Chat
    let onSubmit: (Chat) -> Void
    let onDelete: (Chat) -> Void
    
    var body: some View {
        // TODO: - 텍스트 높낮이 일정하게 맞추기
        ZStack(alignment: .topLeading) {
            emptyContent
                .allowsHitTesting(false)
            
            TextEditor(text: Bindable(chat).content)
                .scrollDisabled(true)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 23, maxHeight: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .frame(minHeight: 23, maxHeight: .infinity, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: chat.content) {
            scheduleDebouncedSubmit(isDelete: $1.isEmpty)
        }
    }
    
    @ViewBuilder
    private var emptyContent: some View {
        Text(placeholder)
            .opacity(chat.content.isEmpty ? 0.5 : 0)
            .foregroundColor(.gray.opacity(0.5))
            .padding(.leading, 5)
    }
    
    private func scheduleDebouncedSubmit(isDelete: Bool = false) {
        debouncingTask?.cancel()  /// 이전에 실행중이던 타이머(Task) 취소
        
        let delay: UInt64 = isDelete ? 1_500_000_000 : 3_000_000_000
        let action = isDelete ? onDelete : onSubmit

        debouncingTask = Task {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                return  /// Task가 cancel되면 아무 작업 안 함
            }
            action(chat)
        }
    }
}

// MARK: - ChatList
fileprivate struct ChatList: View {
    @FocusState.Binding var focusedId: String?
    let chats: [Chat]
    let createChat: (String?) -> Void
    let updateChat: (Chat) -> Void
    let removeChat: (Chat) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(chats) { chat in
                ChatRow(chat: chat, updateChat: updateChat, removeChat: removeChat)
                    .focused($focusedId, equals: chat.id)
                    .contextMenu {
                        removeButton(chat)
                    }

            }
            
            addButton
            Spacer()
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            createChat(nil)
        }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
        .padding(.leading, 25)
        
        Spacer()
    }
    
    @ViewBuilder
    private func removeButton(_ chat: Chat) -> some View {
        Button {
            removeChat(chat)
        } label: {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
    }
}


#Preview {
    VStack {
        ChatBoardView(viewModel: .init(container: .stub, userInfo: .stub))
            .environment(DIContainer.stub)
            .environment(OverlayManager.stub)
            .frame(width: 400, height: 600)
        
        Spacer()
    }
}
