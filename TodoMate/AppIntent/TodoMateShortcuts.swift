//
//  TodoMateShortcuts.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents

struct TodoMateShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddTodoIntent(),
      phrases: [
        "Add Todo in \(.applicationName)",
        "New Todo in \(.applicationName)",
        "Create Todo in \(.applicationName)",
      ],
      shortTitle: "Add Todo",
      systemImageName: "checklist",
    )

    AppShortcut(
      intent: ReadTodosIntent(),
      phrases: [
        "Show Todos in \(.applicationName)",
        "List Todos in \(.applicationName)",
        "Check \(.applicationName)",
      ],
      shortTitle: "Show Todos",
      systemImageName: "list.bullet",
    )

    AppShortcut(
      intent: AddMemoIntent(),
      phrases: [
        "Add Memo in \(.applicationName)",
        "New Memo in \(.applicationName)",
        "Write Memo in \(.applicationName)",
      ],
      shortTitle: "Add Memo",
      systemImageName: "note.text",
    )
  }
}
