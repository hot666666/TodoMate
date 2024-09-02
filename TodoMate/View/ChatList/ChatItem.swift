//
//  ChatItem.swift
//  TodoMate
//
//  Created by hs on 9/1/24.
//

import SwiftUI

struct ChatItem: View {
    private var viewModel: ChatListViewModel
    @State private var debouncer = Debouncer(delay: 0.7)
    @State private var showingPopover: Bool = false
    @State private var localContent: String  /// 실제 서버에 업데이트되기 전, 로컬의 입력상태
    var item: Chat
    @FocusState.Binding var focusedId: String?
    
    init(viewModel: ChatListViewModel, item: Chat, focusedId: FocusState<String?>.Binding) {
        self.viewModel = viewModel
        self.item = item
        self._focusedId = focusedId
        self._localContent = State(initialValue: item.content)
    }
    
    var body: some View {
        if item.isImage {
            imageView
        } else {
            textView
        }
    }
    
    @ViewBuilder
    var imageView: some View {
        HStack {
            AsyncImage(url: URL(string: item.content)){ image in
                image
                    .resizable()
                    .scaledToFit()
                    .containerRelativeFrame(.horizontal) { size, axis in
                        size * 0.3
                    }
                    .onLongPressGesture {
                         showingPopover = true
                     }
                    // TODO: - CustomSheetModifier, Local Cache
                    .popover(isPresented: $showingPopover) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 1024, height: 1024)
                            .padding()
                    }
            } placeholder: {
                ProgressView()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    var textView: some View {
        TextEditor(text: $localContent)
            .textEditorStyle()
            .font(.system(size: 15))
            .focused($focusedId, equals: item.id)
            .shadow(radius: focusedId == item.id ? 5 : 0)
            .onTapGesture { focusedId = item.id }
            .onChange(of: localContent) { oldValue, newValue in
                debouncer.debounce {
                    if newValue.isEmpty {
                        viewModel.remove(item)
                        return
                    }
                    print("[Updating Chat - \(newValue)]")
                    let updatedChat = item
                    updatedChat.content = newValue
                    updatedChat.sign = Const.Signature  /// 동일 사용자인지 구분하여, 같다면 focused가 풀리지 않음
                    viewModel.update(updatedChat)
                }
            }
    }
}
