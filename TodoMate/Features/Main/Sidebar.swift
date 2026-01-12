//
//  Sidebar.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct Sidebar: View {
  @Environment(AppDIContainer.self) private var diContainer
  @Environment(PrivateTodoStore.self) private var todoStore
  @Environment(PrivateMemoStore.self) private var memoStore

  @AppStorage(UserDefaultsKey.cachedProfileName.rawValue)
  private var cachedProfileName: String = ""
  @AppStorage(UserDefaultsKey.cachedGroupName.rawValue)
  private var cachedGroupName: String = ""
  @AppStorage(UserDefaultsKey.cachedUserGroupId.rawValue)
  private var cachedUserGroupId: String = ""

  @Binding var selection: NavigationDestination?

  private var todayTodoCount: Int {
    todoStore.todos.count
  }

  private var memoCount: Int {
    memoStore.memos.count
  }

  private var displayName: String {
    (cachedProfileName.isEmpty ? nil : cachedProfileName) ?? "유저"
  }

  private var hasGroup: Bool {
    !cachedUserGroupId.isEmpty
  }

  private var groupName: String {
    (cachedGroupName.isEmpty ? nil : cachedGroupName) ?? "그룹"
  }

  var body: some View {
    List(selection: $selection) {
      Section {
        NavigationLink(value: NavigationDestination.settings) {
          SidebarProfile(
            displayName: displayName,
            subtitle: nil,
          )
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
}

// MARK: - SidebarProfile

private struct SidebarProfile: View {
  let displayName: String
  let subtitle: String?

  var body: some View {
    HStack(spacing: 12) {
      ProfileAvatarView(displayName: displayName, size: 32)

      VStack(alignment: .leading, spacing: 0) {
        Text(displayName)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationSplitView {
    Sidebar(selection: .constant(.todo))
      .environment(PrivateTodoStore.preview)
      .environment(PrivateMemoStore.preview)
      .environment(AppDIContainer.preview)
  } detail: {
    Text("Detail")
  }
}
