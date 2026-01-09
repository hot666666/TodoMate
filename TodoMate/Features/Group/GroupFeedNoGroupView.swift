//
//  GroupFeedNoGroupView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct GroupFeedNoGroupView: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(NavigationManager.self) private var naviManager

  var body: some View {
    HStack(spacing: 24) {
      JoinGroupCard(sessionStore: sessionStore, naviManager: naviManager)
      CreateGroupCard(sessionStore: sessionStore, naviManager: naviManager)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
    .accessibilityIdentifier("GroupFeedNoGroupView")
  }
}

// MARK: - Subviews

private struct JoinGroupCard: View {
  let sessionStore: SessionStore
  let naviManager: NavigationManager
  @State private var groupId = ""
  @State private var isJoining = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 20) {
      Spacer()

      Image(systemName: "person.badge.plus")
        .font(.system(size: 48))
        .foregroundStyle(Color.blue)

      Text("Join a Group")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundStyle(Color(nsColor: .labelColor))

      Text("Enter a Group ID to join an existing group.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      VStack(spacing: 8) {
        HStack(spacing: 12) {
          TextField("Group ID", text: $groupId)
            .textFieldStyle(.plain)
            .padding(10)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1),
            )

          Button {
            joinGroup()
          } label: {
            if isJoining {
              ProgressView()
                .controlSize(.small)
            } else {
              Text("Join")
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            }
          }
          .buttonStyle(.card(padding: .init(top: 10, leading: 20, bottom: 10, trailing: 20)))
          .disabled(groupId.trimmingCharacters(in: .whitespaces).isEmpty || isJoining)
        }

        if let error = errorMessage {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
        }
      }

      Spacer()
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .cardContainer(cornerRadius: 16)
  }

  private func joinGroup() {
    let trimmedId = groupId.trimmingCharacters(in: .whitespaces)
    guard !trimmedId.isEmpty else { return }

    isJoining = true
    errorMessage = nil

    Task {
      do {
        try await sessionStore.joinGroup(groupId: trimmedId)
        // Navigate to the newly joined group
        naviManager.selection = .group(trimmedId)
      } catch {
        errorMessage = "Failed to join group."
      }
      isJoining = false
    }
  }
}

private struct CreateGroupCard: View {
  let sessionStore: SessionStore
  let naviManager: NavigationManager
  @State private var groupName = ""
  @State private var isCreating = false
  @State private var showingInput = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 16) {
      Spacer()

      Image(systemName: "person.2.circle.fill")
        .font(.system(size: 40))
        .foregroundStyle(Color.green)

      Text("Create Your Own Group")
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(Color(nsColor: .labelColor))

      Text("Start a new group for your team or friends.")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      if showingInput {
        VStack(spacing: 8) {
          TextField("Group name", text: $groupName)
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1),
            )

          HStack(spacing: 12) {
            Button("Cancel") {
              showingInput = false
              groupName = ""
              errorMessage = nil
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.card(padding: .init(top: 8, leading: 16, bottom: 8, trailing: 16)))

            Button {
              createGroup()
            } label: {
              if isCreating {
                ProgressView()
                  .controlSize(.small)
              } else {
                Text("Create")
                  .fontWeight(.medium)
                  .foregroundStyle(.green)
              }
            }
            .buttonStyle(.card(padding: .init(top: 8, leading: 16, bottom: 8, trailing: 16)))
            .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
          }

          if let error = errorMessage {
            Text(error)
              .font(.caption)
              .foregroundStyle(.red)
          }
        }
      } else {
        Button {
          showingInput = true
        } label: {
          Text("Create Group")
            .fontWeight(.medium)
            .foregroundStyle(.green)
        }
        .buttonStyle(.card(padding: .init(top: 8, leading: 16, bottom: 8, trailing: 16)))
      }

      Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .cardContainer(cornerRadius: 12)
  }

  private func createGroup() {
    let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else { return }

    isCreating = true
    errorMessage = nil

    Task {
      do {
        try await sessionStore.createGroup(name: trimmedName)
        // Navigate to the newly created group
        if let newGroupId = sessionStore.user?.groupId, !newGroupId.isEmpty {
          naviManager.selection = .group(newGroupId)
        }
      } catch {
        errorMessage = "Failed to create group."
      }
      isCreating = false
    }
  }
}

#Preview {
  GroupFeedNoGroupView()
    .environment(SessionStore.preview)
    .environment(NavigationManager.preview)
    .frame(width: 800, height: 500)
}
