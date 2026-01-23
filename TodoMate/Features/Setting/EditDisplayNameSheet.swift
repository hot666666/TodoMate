//
//  EditDisplayNameSheet.swift
//  TodoMate
//
//  Created by hs on 1/23/26.
//

import SwiftUI
import TodoMateDomain

struct EditDisplayNameSheet: View {
  @Environment(\.dismiss) private var dismiss
  let currentName: String
  let onSave: (String) -> Void

  @State private var name: String = ""
  @FocusState private var isFocused: Bool

  private var isValid: Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && name.count <= UpdateUserUseCaseImpl.maxDisplayNameLength
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("이름 변경")
        .font(.headline)

      TextField("이름", text: $name)
        .textFieldStyle(.roundedBorder)
        .focused($isFocused)

      Text("\(name.count)/\(UpdateUserUseCaseImpl.maxDisplayNameLength)")
        .font(.caption)
        .foregroundStyle(
          name.count > UpdateUserUseCaseImpl.maxDisplayNameLength ? .red : .secondary)

      HStack(spacing: 12) {
        Button("취소") {
          dismiss()
        }
        .buttonStyle(.bordered)

        Button("저장") {
          onSave(name.trimmingCharacters(in: .whitespacesAndNewlines))
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isValid)
      }
    }
    .padding(24)
    .frame(width: 300)
    .onAppear {
      name = currentName
      isFocused = true
    }
  }
}
