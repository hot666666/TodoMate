//
//  SidebarView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct SidebarView: View {
  @Environment(SessionStore.self) private var sessionStore
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
        Text("Groups")
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
  } detail: {
    Text("Detail")
  }
}
