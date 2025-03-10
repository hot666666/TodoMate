//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 3/3/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @Environment(DIContainer.self) private var container
    @Environment(OverlayManager.self) private var overlayManager
    @State private var cancellable: AnyCancellable?
    
    // TODO: - GroupDashboard에서 그룹 유저를 패치하는 문제
    let userInfo: AuthenticatedUser
    let groupUsers: [User]
    
    var body: some View {
        ScrollView {
            VStack {
                ChatBoardView(viewModel: .init(container: container, userInfo: userInfo))
                TodoBoardView(viewModel: .init(container: container, userInfo: userInfo),
                              users: groupUsers)
            }
            .padding(.horizontal)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createUserTodoTriggered)) { _ in
            /// Debounce 적용 (0.5초 내 중복 호출 무시)
            cancellable?.cancel()
            cancellable = Just(())
                .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
                .sink { _ in
                    Task {
                        await createUserTodo()
                    }
                }
        }
        .onAppear {
            cancellable = nil
        }
    }
    
    @MainActor
    private func createUserTodo() async {
        guard let craetedTodo = await container.todoService.create(from: .init(uid: userInfo.uid)) else { return }
        overlayManager.push(.todo(craetedTodo, isMine: true, update: { _, updatedTodo in
            container.todoService.update(updatedTodo)
        }))
    }
}
