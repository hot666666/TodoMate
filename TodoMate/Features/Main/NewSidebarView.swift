//
//  NewSidebarView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct NewSidebarView: View {
  @Environment(SessionStore.self) private var sessionStore
  @Binding var selection: SidebarSelection?

  var body: some View {
    List(selection: $selection) {
      Section {
        NavigationLink(value: SidebarSelection.settings) {
          SidebarProfileView(
            displayName: sessionStore.user.displayName,
            subtitle: "Pro Member",
          )
        }
        .accessibilityIdentifier("sidebar_profile")
        .buttonStyle(.plain)
      }

      Section {
        NavigationLink(value: SidebarSelection.todo) {
          Label {
            Text("Todo")
          } icon: {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(DesignSystem.Colors.primary)
          }
          .badge(12)
        }
        .accessibilityIdentifier("sidebar_todo")

        NavigationLink(value: SidebarSelection.memo) {
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
        // TODO: Replace with actual groups from sessionStore
        NavigationLink(value: SidebarSelection.group("design-team")) {
          Label {
            Text("Design Team")
          } icon: {
            Image(systemName: "briefcase.fill")
              .foregroundStyle(DesignSystem.Colors.accentIndigo)
          }
        }
        .accessibilityIdentifier("sidebar_group_design-team")
      } header: {
        Text("Groups")
      }

      Section {
        NavigationLink(value: SidebarSelection.noGroups) {
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
    NewSidebarView(selection: .constant(.todo))
      .environment(SessionStore.preview)
  } detail: {
    Text("Detail")
  }
}
