//
//  HomeScreen.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct HomeScreen: View {
  @Environment(DIContainer.self) var container
  @Environment(MainVM.self) var mainVM
  @Environment(SessionStore.self) var sessionStore
  @Environment(MessageStore.self) var messageStore
  @Environment(TodoStore.self) var todoStore
  @Environment(MemoStore.self) var memoStore
  @Environment(OverlayManager.self) var overlayManager

  @State var homeScreenVM: HomeScreenVM

  private func presentCalendarFullScreen() {
    overlayManager.presentFullScreen {
      CalendarScreen(calendarVM: .init(container: container))
    }
  }

  private func refresh() async {
    let userIds = sessionStore.userGroup.map(\.id)
    // 모든 사용자의 캐싱 데이터 로드
    await memoStore.load(for: userIds)
    await todoStore.load(for: userIds, currentUserId: sessionStore.userId)
    // 메모 데이터 로드
    await memoStore.load(for: userIds, useCache: false)
    // Todo 데이터 실시간 동기화
    await todoStore.observe(for: userIds)
  }
}

extension HomeScreen {
  var body: some View {
    VStack {
      VStack(spacing: HomeDesignSystem.Layout.sectionSpacing) {
        UserSelectionHeader()
          .padding([.horizontal, .top], HomeDesignSystem.Padding.large)
          .shadow(radius: HomeDesignSystem.Shadow.light)

        if homeScreenVM.showDropdown {
          MemoSection()
            .padding(.horizontal, HomeDesignSystem.Padding.small)
        }

        TodoListSection()
          .background(.ultraThinMaterial, in: .rect(cornerRadius: HomeDesignSystem.CornerRadius.large))
          .shadow(radius: HomeDesignSystem.Shadow.light)
          .padding([.horizontal, .bottom], HomeDesignSystem.Padding.large)
      }
    }
    .environment(homeScreenVM)
    .task(id: mainVM.refreshSessionTrigger) {
      await refresh()
    }
    .onAppear {
      // 초기 선택 유저 설정
      homeScreenVM.selectedUserId = sessionStore.userId
    }
  }
}

#Preview {
  HomeScreen(homeScreenVM: .init())
    .environment(DIContainer.preview)
    .environment(MainVM())
    .environment(OverlayManager())
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .frame(width: 500, height: 400)
}
