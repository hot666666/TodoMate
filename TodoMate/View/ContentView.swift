//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(DIContainer.self) private var container: DIContainer
    @Environment(AppState.self) private var appState: AppState
    @State private var userManager: UserManager = .init()

    var body: some View {
        ScrollView {
            VStack {
                chatSection
                    .padding(.top)

                userSections
                    .padding(.top, 5)
            }
            .disabled(appState.isSelectedTodo)

            Spacer()
                .frame(height: 50)
        }
        .task {
            await userManager.fetch()
        }
        .customSheet(selectedItem: appState.selectedTodo) {
            TodoSheet(todo: $0)
        }
        .customOverlayView(isPresented: appState.popover, overlayPosition: appState.popoverPosition) {
            DateSettingView()
        }
    }

    @ViewBuilder
    private var chatSection: some View {
        ExpandableView(title: "채팅", storageKey: "chatlist") {
            ChatList(viewModel: .init(container: container))
                .padding(.horizontal, 5)
        }
    }

    @ViewBuilder
    private var userSections: some View {
        ForEach(userManager.users) { user in
            userSection(for: user)
        }
    }

    private func userSection(for user: User) -> some View {
        ExpandableView(title: user.name, storageKey: "user_\(user.fid)") {
            VStack {
                calendarView(for: user)
                    .padding(.horizontal, 30)

                todoBoxView(for: user)
                    .padding(.horizontal, 30)
            }
        }
    }

    private func calendarView(for user: User) -> some View {
        ExpandableView(title: "캘린더", storageKey: "calendar_\(user.fid)") {
            CalendarWithTodo(viewModel: .init(container: container, userId: user.fid))
        }
    }

    private func todoBoxView(for user: User) -> some View {
        TodoBox(viewModel: .init(container: container, userId: user.fid))
    }
}

#Preview {
    ContentView()
        .environment(DIContainer.stub)
        .environment(AppState())
}
