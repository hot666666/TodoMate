//
//  MarkdownMessageView.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//


//
//  MarkdownMessageView.swift
//  TodoMate
//
//  Created by hs on 3/12/25.
//

import SwiftUI
import MarkdownUI

struct MarkdownMessageView: View {
	@State var messageStore: MessageStore
	let userInfo: AuthenticatedUser
	
	var body: some View {
		VStack {
			List {
				ForEach(messageStore.messages) { message in
						VStack {
							MessageView(message: message, userInfo: userInfo)
						}
					}
					.padding()
				
				Button {
					do {
						try messageStore.createMessage(lastModifiedUser: userInfo.uid)
					} catch {
						print(error)
					}
				} label: {
					Image(systemName: "plus")
				}
				.hoverButtonStyle()
			}
		}
		.environment(messageStore)
		.task {
			try? await messageStore.readMessages()
			await messageStore.observeMessageChanges()
		}
	}
}

fileprivate struct MessageView: View {
	@Environment(MessageStore.self) private var messageStore
	private let userInfo: AuthenticatedUser
	
	@Bindable var message: MessageModel
	@State private var localContent: String
	
	init(message: MessageModel, userInfo: AuthenticatedUser) {
		self.message = message
		self.userInfo = userInfo
		self._localContent = State(initialValue: message.content)
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

extension MessageView {
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
		.border(.red, width: 1)
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
		HStack {
			Markdown(localContent.isEmpty ? "클릭하여 입력하세요." : localContent)
				.opacity(localContent.isEmpty ? 0.5 : 1)
				.padding(.leading, 5)
				.background(Color.clear)
			Spacer()
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
			toggleMode()
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
	MarkdownMessageView(messageStore: MessageStore.stub, userInfo: AuthenticatedUser.stub)
	.frame(width: 450, height: 450)
}
