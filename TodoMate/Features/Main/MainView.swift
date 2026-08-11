import SwiftUI
import TodoMatePresentation

struct MainView: View {
  private let container: AppDIContainer

  init(container: AppDIContainer) {
    self.container = container
  }

  var body: some View {
    ProjectAppScreen(
      projectClient: container.core.projectClient,
      todoClient: container.core.todoClient,
    )
  }
}

#Preview {
  MainView(container: .preview)
    .frame(width: 1000, height: 625)
}
