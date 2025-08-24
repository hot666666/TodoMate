//
//  TodoContentTextField.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoContentTextField: View {
  @Binding var content: String
  @FocusState.Binding var focusedField: TodoSheet.SheetField?
  let onSubmit: () -> Void

  var body: some View {
    TextField("이름없음", text: $content)
      .textFieldStyle(.plain)
      .font(TodoSheetDesignSystem.Component.Typography.titleFont)
      .bold()
      .focused($focusedField, equals: .content)
      .submitLabel(.done)
      .onSubmit {
        if content.isEmpty {
          focusedField = .content
        } else {
          onSubmit()
        }
      }
  }
}
