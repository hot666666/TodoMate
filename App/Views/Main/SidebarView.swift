//
//  SidebarView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

enum SidebarSelection: Hashable, Identifiable {
  case todo
  case memo
  case settings
  case group(String) // Group ID
  case noGroups

  var id: Self { self }

  var title: String {
    switch self {
    case .todo: "Todo"
    case .memo: "Memo"
    case .settings: "Settings"
    case let .group(groupId): groupId
    case .noGroups: "No Groups Joined"
    }
  }
}

struct SidebarView: View {
  @Binding var selection: SidebarSelection?

  var body: some View {
    List(selection: $selection) {
      Section {
        NavigationLink(value: SidebarSelection.settings) {
          SidebarProfileView()
        }
        .accessibilityIdentifier("sidebar_profile")
        .buttonStyle(.plain) // Remove default button style if needed, or let List handle it
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
        Text("Alex Morgan")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text("Pro Member")
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
  } detail: {
    Text("Detail")
  }
}
