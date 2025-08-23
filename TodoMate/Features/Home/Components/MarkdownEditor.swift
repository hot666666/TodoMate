//
//  MarkdownEditor.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import SwiftUI

struct MarkdownEditor: View {
  @FocusState private var isTextEditorFocused: Bool
  @State private var editingContent: String = ""

  let content: String
  let isEditable: Bool
  @Binding var isEditing: Bool
  let onSave: (String) -> Void

  private func startEditing() {
    editingContent = content
    isEditing = true
    isTextEditorFocused = true
  }

  private func saveChanges() {
    onSave(editingContent)
    isEditing = false
  }

  private func cancelEditing() {
    editingContent = content
    isEditing = false
  }
}

extension MarkdownEditor {
  var body: some View {
    ScrollView {
      if isEditing {
        editingView
      } else {
        displayView
      }
    }
    .onAppear {
      editingContent = content
    }
  }

  private var displayView: some View {
    VStack {
      if content.isEmpty {
        Text(isEditable ? "메모를 추가하려면 클릭하세요" : "작성된 메모가 없습니다")
          .foregroundColor(.secondary)
          .italic()
      } else {
        MarkdownRenderer(content: content)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, HomeDesignSystem.Padding.xSmall)
    .padding(.horizontal, HomeDesignSystem.Padding.medium)
    .onTapGesture {
      if isEditable {
        startEditing()
      }
    }
  }

  private var editingView: some View {
    VStack(alignment: .trailing, spacing: HomeDesignSystem.Padding.xSmall) {
      TextEditor(text: $editingContent)
        .focused($isTextEditorFocused)
        .scrollContentBackground(.hidden)
        .frame(minHeight: HomeDesignSystem.Component.Memo.textEditorMinHeight, maxHeight: HomeDesignSystem.Component.Memo.textEditorMaxHeight, alignment: .top)
        .padding(.horizontal, HomeDesignSystem.Padding.xSmall)
        .offset(x: -3, y: 3)
        .overlay(alignment: .topLeading) {
          if editingContent.isEmpty {
            Text("마크다운으로 메모를 작성하세요...")
              .foregroundColor(.secondary)
              .offset(x: 2 + HomeDesignSystem.Padding.small)
              .allowsHitTesting(false)
          }
        }
        .onKeyPress(.return, phases: .down) { key in
          if key.modifiers.contains(.command) {
            saveChanges()
            return .handled
          }
          return .ignored
        }

      HStack(spacing: HomeDesignSystem.Padding.small) {
        Button("취소") {
          cancelEditing()
        }
        .buttonStyle(GlassmorphismButtonStyle(disabled: true))

        Button("저장") {
          saveChanges()
        }
        .buttonStyle(GlassmorphismButtonStyle(disabled: false))
        .keyboardShortcut(.return, modifiers: .command)
      }
      .padding(.horizontal, HomeDesignSystem.Padding.xSmall)
    }
  }
}

#Preview {
  @State @Previewable var isEditing1 = false
  @State @Previewable var isEditing2 = false
  @State @Previewable var isEditing3 = false

  VStack(spacing: 20) {
    MarkdownEditor(
      content: "# 샘플 메모\n\n- 첫 번째 항목\n- 두 번째 항목\n\n**볼드 텍스트**와 *이탤릭 텍스트*",
      isEditable: true,
      isEditing: $isEditing1
    ) { _ in }

    Divider()

    MarkdownEditor(
      content: "",
      isEditable: true,
      isEditing: $isEditing2
    ) { _ in }

    Divider()

    MarkdownEditor(
      content: "## 읽기 전용\n\n이 메모는 수정할 수 없습니다.",
      isEditable: false,
      isEditing: $isEditing3
    ) { _ in }
  }
  .padding()
  .frame(width: 400, height: 600)
}
