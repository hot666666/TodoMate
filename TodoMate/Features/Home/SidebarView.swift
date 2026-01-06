//
//  SidebarView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct SidebarView: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(NetworkModeManager.self) private var networkManager
  @Binding var selection: NavigationDestination?

  var body: some View {
    List(selection: $selection) {
      Section {
        NavigationLink(value: NavigationDestination.settings) {
          SidebarProfileView(
            displayName: sessionStore.user?.displayName ?? "Guest",
            subtitle: "Pro Member",
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
          .badge(12)
        }
        .accessibilityIdentifier("sidebar_todo")

        NavigationLink(value: NavigationDestination.memo) {
          Label {
            Text("Memo")
          } icon: {
            Image(systemName: "square.text.square.fill")
              .foregroundStyle(DesignSystem.Colors.trafficYellow)
          }
        }
        .accessibilityIdentifier("sidebar_memo")
      } header: {
        Text("Private")
      }

      Section {
        if sessionStore.userGroupId.isEmpty {
          Label {
            Text("No Groups Joined")
              .italic()
              .foregroundStyle(.secondary)
          } icon: {
            Image(systemName: "person.2.fill")
              .foregroundStyle(.secondary)
          }
          .accessibilityIdentifier("sidebar_noGroups")
        } else {
          NavigationLink(value: NavigationDestination.group(sessionStore.userGroupId)) {
            Label {
              // TODO: 그룹 이름을 별도로 관리하거나, 서버에서 가져와야 함
              Text("Design Team")
            } icon: {
              Image(systemName: "briefcase.fill")
                .foregroundStyle(DesignSystem.Colors.accentIndigo)
            }
          }
          .accessibilityIdentifier("sidebar_group_\(sessionStore.userGroupId)")
        }
      } header: {
        Text("Groups")
      }
    }
    .frame(minWidth: 200)
    .listStyle(.sidebar)
    .safeAreaInset(edge: .bottom) {
      networkToggle
        .padding()
    }
  }

  // MARK: - Network Toggle

  private var networkToggle: some View {
    HStack(alignment: .center) {
      Image(systemName: networkManager.isOnline ? "wifi" : "wifi.slash")
      Text(networkManager.isOnline ? "Online" : "Offline")
      Spacer()
      Toggle(
        "",
        isOn: Binding(
          get: { networkManager.isOnline },
          set: { newValue in
            Task {
              await networkManager.setOnline(newValue)
            }
          },
        ),
      )
      .labelsHidden()
      .toggleStyle(.switch)
    }
    .disabled(networkManager.isTransitioning)
    .accessibilityIdentifier("network_toggle")
  }
}

// MARK: - SidebarProfileView

private struct SidebarProfileView: View {
  let displayName: String
  let subtitle: String

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.orange.opacity(0.8))
        .frame(width: 32, height: 32)
        .overlay {
          Image(systemName: "person.fill")
            .foregroundStyle(.white)
            .font(.caption)
        }

      VStack(alignment: .leading, spacing: 0) {
        Text(displayName)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationSplitView {
    SidebarView(selection: .constant(.todo))
      .environment(SessionStore.preview)
      .environment(NetworkModeManager.preview)
  } detail: {
    Text("Detail")
  }
}
