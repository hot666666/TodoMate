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
  // MARK: - Properties

  @Environment(NavigationManager.self) private var naviManager
  @Environment(TodoBoardStore.self) private var todoStore
  @Environment(MemoStore.self) private var memoStore

  @AppStorage(UserDefaultsKey.cachedProfileName.rawValue)
  private var cachedProfileName: String = ""
  @AppStorage(UserDefaultsKey.cachedGroupName.rawValue)
  private var cachedGroupName: String = ""
  @AppStorage(UserDefaultsKey.cachedUserGroupId.rawValue)
  private var cachedUserGroupId: String = ""

  // MARK: - Computed Properties

  private var todayTodoCount: Int {
    todoStore.todos.count(where: { $0.date.isToday })
  }

  private var memoCount: Int {
    memoStore.memos.count
  }

  private var hasGroup: Bool {
    !cachedUserGroupId.isEmpty
  }

  private var groupName: String {
    (cachedGroupName.isEmpty ? nil : cachedGroupName) ?? "그룹"
  }

  // MARK: - Body

  var body: some View {
    List(selection: Bindable(naviManager).selection) {
      Section {
        NavigationLink(value: NavigationDestination.settings) {
          if cachedProfileName.isEmpty {
            placeholderProfile
          } else {
            userProfile
          }
        }
        .accessibilityIdentifier("sidebar_profile")
        .buttonStyle(.plain)
      }

      Section {
        NavigationLink(value: NavigationDestination.todo) {
          todoLabel
        }
        .accessibilityIdentifier("sidebar_todo")

        NavigationLink(value: NavigationDestination.memo) {
          memoLabel
        }
        .accessibilityIdentifier("sidebar_memo")

        NavigationLink(value: NavigationDestination.deletedItems) {
          trashLabel
        }
        .accessibilityIdentifier("sidebar_trash")
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
          ConnectivityToggle()
            .padding(.trailing, 8)
        }
      }
    }
    .frame(minWidth: 200)
    .listStyle(.sidebar)
  }

  // MARK: - Subviews

  private var todoLabel: some View {
    Label {
      Text("Todo")
    } icon: {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(DesignSystem.Colors.primary)
    }
    .badge(Text("\(todayTodoCount)").monospacedDigit())
  }

  private var memoLabel: some View {
    Label {
      Text("Memo")
    } icon: {
      Image(systemName: "square.text.square.fill")
        .foregroundStyle(DesignSystem.Colors.trafficYellow)
    }
    .badge(Text("\(memoCount)").monospacedDigit())
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

  private var trashLabel: some View {
    Label {
      Text("Trash")
    } icon: {
      Image(systemName: "trash")
        .foregroundStyle(.secondary)
    }
  }

  private var placeholderProfile: some View {
    UserProfile(
      displayName: "TodoMate",
      style: .compact,
      avatar: {
        AppImage(size: 32)
      },
    )
  }

  private var userProfile: some View {
    UserProfile(
      displayName: cachedProfileName,
      style: .compact,
      avatar: {
        DefaultAvatar(displayName: cachedProfileName, size: 32)
      },
    )
  }
}

#Preview {
  NavigationSplitView {
    Sidebar()
      .environment(TodoBoardStore.preview)
      .environment(MemoStore.preview)
      .environment(NavigationManager.preview)
  } detail: {
    Text("Detail")
  }
}
