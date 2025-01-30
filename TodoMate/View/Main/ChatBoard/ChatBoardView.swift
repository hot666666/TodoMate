//
//  ChatBoardView.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI

struct ChatBoardView: View {
    @State private var viewModel: ChatBoardViewModel
    
    init(viewModel: ChatBoardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ExpandableView(
            storageKey: "chatlist",
            title: {
                Text("채팅")
            },
            content: {
                ChatBoardContainer()
                    .task {
                        await viewModel.observeChanges()
                    }
                    .environment(viewModel)
                    .padding(.horizontal, 10)
            })
        .padding(.bottom)
    }
}

// MARK: - ChatBoardContainer
fileprivate struct ChatBoardContainer: View {
    @Environment(OverlayManager.self) private var overlayManager
    @Environment(ChatBoardViewModel.self) private var viewModel
    @FocusState private var focusedId: String?
    
    var body: some View {
        ZStack {
            clearFocusBackground
                .onTapGesture { clearFocus() }
            
            VStack(alignment: .leading) {
                ForEach(viewModel.chats) { chat in
                    ChatRow(chat: chat, focusedId: $focusedId)
                        .contextMenu {
                            removeButton(chat)
                        }
                }
                addButton
                Spacer()
            }
            .onChange(of: overlayManager.isOverlayPresented) {
                if $1 { clearFocus() }
            }
        }
    }
    
    @ViewBuilder
    private var clearFocusBackground: some View {
        Color.clear
            .contentShape(.rect)
    }
    
    @ViewBuilder
    private var addButton: some View {
        HStack{
            Button(action: {
                viewModel.createChat()
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
        Button(role: .destructive) {
            viewModel.removeChat(chat)
        } label: {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
    }
    
    private func clearFocus() { focusedId = nil }
}

// MARK: - ChatRow
fileprivate struct ChatRow: View {
    @Environment(ChatBoardViewModel.self) private var viewModel
    @State private var isHovered: Bool = false
    
    let chat: Chat
    @FocusState.Binding var focusedId: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // TODO: - 채팅 이동 처리
            ellipsis
                .opacity(isHovered ? 1 : 0)
                
            ChatInput(chat: chat,
                      onSubmit: viewModel.updateChat,
                      onDelete: viewModel.removeChat)
            .focused($focusedId, equals: chat.id)
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
    
    var chat: Chat
    let placeholder: String = "메시지를 입력하세요"
    let onSubmit: (Chat) -> Void
    let onDelete: (Chat) -> Void
    
    var body: some View {
        // TODO: - 텍스트 높낮이 일정하게 맞추기
        ZStack(alignment: .topLeading) {
            /// placeholder
            Group {
                if chat.content.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.leading, 5)
#if os(iOS)
                                .padding(.top, 10)
#endif
                }
            }
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

#Preview {
    VStack {
        ChatBoardView(viewModel: .init(container: .stub, userInfo: .stub))
            .environment(DIContainer.stub)
            .environment(OverlayManager.stub)
            .frame(width: 400, height: 600)
        
        Spacer()
    }
}
