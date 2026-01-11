//
//  PrivateSidebarView.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import SwiftUI

struct PrivateSidebarView: View {
  @Environment(PrivateTodoStore.self) private var todoStore
  @Binding var selection: NavigationDestination?

  private var todayTodoCount: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    // Flatten all todos for counting (assuming single local user context for now)
    let allTodos = todoStore.todos.values.flatMap(\.self)
    return allTodos.count(where: { calendar.startOfDay(for: $0.date) == today })
  }

  var body: some View {
    List(selection: $selection) {
      Section {
        NavigationLink(value: NavigationDestination.settings) {
          SidebarProfileView(
            displayName: "Offline User", // TODO: Get from UserDefaults or Core
            subtitle: "Local Mode",
          )
        }
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
      } header: {
        Text("Private")
      }
    }
    .frame(minWidth: 200)
    .listStyle(.sidebar)
    .safeAreaInset(edge: .bottom) {
      // Network Toggle or Placeholder for "Go Online"
      // Since this is strictly Private Mode (Offline), we might want a button to switch back.
      // But RootView controls this via AppStorage.
      // We can add the toggle here strictly for switching modes.
      PrivateNetworkToggle()
    }
  }
}

private struct PrivateNetworkToggle: View {
  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false

  var body: some View {
    Button {
      isPublicModeEnabled = true
    } label: {
      HStack {
        Image(systemName: "icloud.slash")
        Text("Go Online")
        Spacer()
        Image(systemName: "chevron.right")
      }
      .padding()
      .background(Color.secondary.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
  }
}

// Reusing SidebarProfileView logic or definition from SidebarView if public,
// but since SidebarView is private, we redefine a simple one here.
private struct SidebarProfileView: View {
  let displayName: String
  let subtitle: String?

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "person.circle.fill")
        .resizable()
        .frame(width: 32, height: 32)
        .foregroundStyle(.secondary)

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
  PrivateSidebarView(selection: .constant(.todo))
    .environment(PrivateTodoStore.preview)
}
