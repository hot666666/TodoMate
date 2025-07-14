//
//  DraggedTodo.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DraggedTodo: Codable, Transferable {
  let todoId: String
  let sourceDate: Date
  let content: String

  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(for: DraggedTodo.self, contentType: .data)
  }
}
