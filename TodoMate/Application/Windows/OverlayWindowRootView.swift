//
//  OverlayWindowRootView.swift
//  TodoMate
//
//  Created by hs on 6/7/25.
//

import SimpleOverlaySystem
import SwiftData
import SwiftUI
import TodoMateDomain

struct OverlayWindowRootView: View {
  @Environment(\.overlayManager) private var overlayManager

  let todo: Todo?
  let onClose: () -> Void
  let diContainer: AppDIContainer
  let todoStore: PrivateTodoStore

  // 임시 상태 관라 (실제 구현 시 Store 등 사용 고려)
  @State private var localTodo: EditableTodo

  init(
    todo: Todo?, onClose: @escaping () -> Void, diContainer: AppDIContainer,
    todoStore: PrivateTodoStore,
  ) {
    self.todo = todo
    self.onClose = onClose
    self.diContainer = diContainer
    self.todoStore = todoStore

    // Todo가 있으면 수정 모드, 없으면 생성 모드
    if let todo {
      _localTodo = State(initialValue: EditableTodo(from: todo))
    } else {
      _localTodo = State(
        initialValue: EditableTodo(owner: ""))
    }
  }

  var body: some View {
    Color.clear
      .frame(width: 500, height: 600) // 넉넉한 히트박스/레이아웃 영역
      .onAppear(perform: presentTodoSheet)
  }

  private func presentTodoSheet() {
    // TodoSheet을 오버레이로 띄움
    overlayManager?.presentCentered(
      dismissPolicy: .tap, // Sheet 내부에서 닫기 제어
      barrier: .passthrough,
      backdropOpacity: 0.0, // 투명
      offset: CGPoint(x: 0, y: 0),
    ) {
      TodoSheet(editableTodo: localTodo)
        .environment(diContainer) // DI 주입 보장
        .environment(todoStore) // TodoStore 주입
        .onDisappear {
          // 오버레이가 사라지면 윈도우도 닫기 요청
          onClose()
        }
    }
  }
}
