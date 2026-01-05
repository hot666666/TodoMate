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
            displayName: sessionStore.user.displayName,
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
        ForEach(sessionStore.userGroupIds, id: \.self) { groupId in
          NavigationLink(value: NavigationDestination.group(groupId)) {
            Label {
              Text(sessionStore.userGroupDisplayNames[groupId] ?? "Unknown Group")
            } icon: {
              Image(systemName: "briefcase.fill")
                .foregroundStyle(DesignSystem.Colors.accentIndigo)
            }
          }
          .accessibilityIdentifier("sidebar_group_\(groupId)")
        }
      } header: {
        HStack {
          Text("Groups")
          Spacer()
          networkToggle
        }
      }

      Section {
        NavigationLink(value: NavigationDestination.noGroups) {
          Label {
            Text("No Groups Joined")
              .italic()
              .foregroundStyle(.secondary)
          } icon: {
            Image(systemName: "person.2.fill")
              .foregroundStyle(.secondary)
          }
        }
        .accessibilityIdentifier("sidebar_noGroups")
      }
    }
    .listStyle(.sidebar)
  }

  // MARK: - Network Toggle

  private var networkToggle: some View {
    Button {
      Task {
        await networkManager.toggle()
      }
    } label: {
      HStack(spacing: 4) {
        Image(systemName: networkManager.isOnline ? "wifi" : "wifi.slash")
          .font(.caption2)
        Text(networkManager.isOnline ? "Online" : "Offline")
          .font(.caption2)
      }
      .foregroundStyle(networkManager.isOnline ? .green : .secondary)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        Capsule()
          .fill(networkManager.isOnline ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1)),
      )
    }
    .buttonStyle(.plain)
    .disabled(networkManager.isTransitioning)
    .accessibilityIdentifier("network_toggle")
  }
}

private struct SidebarProfileView: View {
  let displayName: String
  let subtitle: String

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.orange.opacity(0.8))
        .frame(width: 40, height: 40)
        .overlay {
          Image(systemName: "person.fill")
            .foregroundStyle(.white)
        }

      VStack(alignment: .leading, spacing: 2) {
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
      .environment(NetworkModeManager())
  } detail: {
    Text("Detail")
  }
}
