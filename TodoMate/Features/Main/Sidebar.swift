//
//  Sidebar.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//
//

import Common
import SwiftData
import SwiftUI
import TodoMateDomain

struct Sidebar: View {
  @Environment(AppDIContainer.self) private var diContainer
  @Environment(LocalTodoHelper.self) private var todoHelper
  @Environment(LocalMemoHelper.self) private var memoHelper

  @AppStorage(UserDefaultsKey.cachedProfileName.rawValue)
  private var cachedProfileName: String = ""
  @AppStorage(UserDefaultsKey.cachedGroupName.rawValue)
  private var cachedGroupName: String = ""
  @AppStorage(UserDefaultsKey.cachedUserGroupId.rawValue)
  private var cachedUserGroupId: String = ""

  @Binding var selection: NavigationDestination?

  @State private var todayTodoCount: Int = 0
  @State private var memoCount: Int = 0

  var body: some View {
    List(selection: $selection) {
      Section {
        NavigationLink(value: NavigationDestination.settings) {
          if cachedProfileName.isEmpty {
            UserProfileView(
              displayName: "TodoMate",
              style: .compact,
              avatar: {
                AppImage(size: 32)
              },
            )
          } else {
            UserProfileView(
              displayName: cachedProfileName,
              style: .compact,
              avatar: {
                DefaultAvatar(displayName: cachedProfileName, size: 32)
              },
            )
          }
        }
        .accessibilityIdentifier("sidebar_profile")
        .buttonStyle(.plain)
      }

      Section {
        NavigationLink(value: NavigationDestination.todo) {
          Label {
            Text("Todo")
          } icon: {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(DesignSystem.Colors.primary)
          }
          .badge(Text("\(todayTodoCount)").monospacedDigit())
        }
        .accessibilityIdentifier("sidebar_todo")

        NavigationLink(value: NavigationDestination.memo) {
          Label {
            Text("Memo")
          } icon: {
            Image(systemName: "square.text.square.fill")
              .foregroundStyle(DesignSystem.Colors.trafficYellow)
          }
          .badge(Text("\(memoCount)").monospacedDigit())
        }
        .accessibilityIdentifier("sidebar_memo")
      } header: {
        Text("Private")
      }

      Section {
        NavigationLink(value: NavigationDestination.group) {
          if hasGroup {
            groupLabel
          } else {
            noGroupLabel
          }
        }
        .accessibilityIdentifier("sidebar_group")
      } header: {
        HStack {
          Text("Public")
          Spacer()
          PublicConnectivityToggle()
            .padding(.trailing, 8)
        }
      }
    }
    .frame(minWidth: 200)
    .listStyle(.sidebar)
    .task(id: [todoHelper.refreshClock, memoHelper.refreshClock]) {
      await refreshCounts()
    }
  }

  private var groupLabel: some View {
    Label {
      Text(groupName)
    } icon: {
      Image(systemName: "person.2.fill")
        .foregroundStyle(DesignSystem.Colors.accentIndigo)
    }
  }

  private var noGroupLabel: some View {
    Label {
      Text("No Groups Joined")
        .italic()
        .foregroundStyle(.secondary)
    } icon: {
      Image(systemName: "person.2.fill")
        .foregroundStyle(.secondary)
    }
  }

  private var hasGroup: Bool {
    !cachedUserGroupId.isEmpty
  }

  private var groupName: String {
    (cachedGroupName.isEmpty ? nil : cachedGroupName) ?? "그룹"
  }

  private func refreshCounts() async {
    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)

    // TODO: All todos for today
    if let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(
      -1) {
      let query = TodoQuery(filters: [.dateRange(startOfDay ... endOfDay)])
      if let count = try? await diContainer.core.fetchTodoCountUseCase.execute(query: query) {
        todayTodoCount = count
      }
    }

    // Memo: All memos
    if let count = try? await diContainer.core.fetchMemoCountUseCase.execute(userId: "") {
      memoCount = count
    }
  }
}

#Preview {
  NavigationSplitView {
    Sidebar(selection: .constant(.todo))
      .environment(AppDIContainer.preview)
      .environment(LocalTodoHelper.preview)
      .environment(LocalMemoHelper.preview)
  } detail: {
    Text("Detail")
  }
}
