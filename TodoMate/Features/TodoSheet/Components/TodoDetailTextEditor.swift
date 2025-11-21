//
//  TodoDetailTextEditor.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoDetailTextEditor: View {
  @Binding var detail: String
  let onSubmit: () -> Void

  var body: some View {
    PlaceholderTextEditor(
      text: $detail,
      placeholder: "메모",
      minHeight: TodoSheetDesignSystem.Component.TextEditor.minHeight,
      maxHeight: TodoSheetDesignSystem.Component.TextEditor.maxHeight,
      onSubmit: onSubmit
    )
  }
}
