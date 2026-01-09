//
//  SettingView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct SettingView: View {
  @Environment(SessionStore.self) private var sessionStore
  @State private var showLogoutConfirmation = false
  @State private var showLeaveGroupConfirmation = false
  @State private var showEditNameSheet = false
  @State private var editingName = ""

  private var hasGroup: Bool {
    !sessionStore.userGroupId.isEmpty
  }

  private var memberCount: Int {
    sessionStore.groupMembers.count
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Profile Section
        profileSection

        // Group Section
        groupSection

        // App Section
        appSection
      }
      .accessibilityIdentifier("settings_view")
      .padding(32)
      .frame(maxWidth: 500)
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .confirmationDialog(
      "Leave Group",
      isPresented: $showLeaveGroupConfirmation,
      titleVisibility: .visible,
    ) {
      Button("Leave", role: .destructive) {
        Task {
          await sessionStore.leaveGroup()
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Are you sure you want to leave this group? You'll need an invitation to rejoin.")
    }
    .confirmationDialog(
      "Sign Out",
      isPresented: $showLogoutConfirmation,
      titleVisibility: .visible,
    ) {
      Button("Sign Out", role: .destructive) {
        sessionStore.signOut()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Are you sure you want to sign out of your account?")
    }
    .sheet(isPresented: $showEditNameSheet) {
      EditDisplayNameSheet(
        currentName: sessionStore.user?.displayName ?? "",
        onSave: { newName in
          Task {
            await updateDisplayName(newName)
          }
        },
      )
    }
  }

  // MARK: - Profile Section

  private var profileSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Profile")
        .font(.headline)
        .foregroundStyle(.secondary)

      HStack(spacing: 16) {
        // Avatar
        ProfileAvatarView(
          displayName: sessionStore.user?.displayName ?? "?",
          size: 64,
        )

        VStack(alignment: .leading, spacing: 4) {
          Text(sessionStore.user?.displayName ?? "Guest")
            .font(.title3)
            .fontWeight(.semibold)
        }

        Spacer()

        Button("Edit") {
          editingName = sessionStore.user?.displayName ?? ""
          showEditNameSheet = true
        }
        .buttonStyle(.bordered)
      }
      .padding(16)
      .background(Color(nsColor: .controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  // MARK: - Group Section

  private var groupSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Group")
        .font(.headline)
        .foregroundStyle(.secondary)

      VStack(spacing: 0) {
        if hasGroup {
          // Current Group
          HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
              .font(.system(size: 24))
              .foregroundStyle(.blue)
              .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
              Text("My Group")
                .font(.subheadline)
                .fontWeight(.medium)
              Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Joined")
              .font(.caption)
              .foregroundStyle(.green)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.green.opacity(0.1))
              .clipShape(Capsule())
          }
          .padding(16)

          Divider()

          // Leave Group
          Button {
            showLeaveGroupConfirmation = true
          } label: {
            HStack {
              Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(.red)
                .frame(width: 40)
              Text("Leave Group")
                .foregroundStyle(.red)
              Spacer()
            }
            .padding(16)
          }
          .buttonStyle(.plain)
        } else {
          // No group
          HStack(spacing: 12) {
            Image(systemName: "person.2.slash")
              .font(.system(size: 24))
              .foregroundStyle(.secondary)
              .frame(width: 40)

            Text("그룹 없음")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            Spacer()
          }
          .padding(16)
        }
      }
      .background(Color(nsColor: .controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  // MARK: - App Section

  private var appSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("App")
        .font(.headline)
        .foregroundStyle(.secondary)

      VStack(spacing: 0) {
        // Sign Out
        Button {
          showLogoutConfirmation = true
        } label: {
          HStack {
            Image(systemName: "arrow.right.square")
              .foregroundStyle(.red)
              .frame(width: 40)
            Text("Sign Out")
              .foregroundStyle(.red)
            Spacer()
          }
          .padding(16)
        }
        .buttonStyle(.plain)
      }
      .background(Color(nsColor: .controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  // MARK: - Actions

  private func updateDisplayName(_ newName: String) async {
    guard var user = sessionStore.user else { return }
    user.displayName = newName
    user.updatedAt = Date()

    do {
      try await sessionStore.updateUser(user)
    } catch {
      Log.error("Failed to update display name: \(error)", category: .auth)
    }
  }
}

// MARK: - Edit Display Name Sheet

private struct EditDisplayNameSheet: View {
  @Environment(\.dismiss) private var dismiss
  let currentName: String
  let onSave: (String) -> Void

  @State private var name: String = ""
  @FocusState private var isFocused: Bool

  private var isValid: Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && name.count <= UpdateUserUseCaseImpl.maxDisplayNameLength
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("이름 변경")
        .font(.headline)

      TextField("이름", text: $name)
        .textFieldStyle(.roundedBorder)
        .focused($isFocused)

      Text("\(name.count)/\(UpdateUserUseCaseImpl.maxDisplayNameLength)")
        .font(.caption)
        .foregroundStyle(
          name.count > UpdateUserUseCaseImpl.maxDisplayNameLength ? .red : .secondary)

      HStack(spacing: 12) {
        Button("취소") {
          dismiss()
        }
        .buttonStyle(.bordered)

        Button("저장") {
          onSave(name.trimmingCharacters(in: .whitespacesAndNewlines))
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isValid)
      }
    }
    .padding(24)
    .frame(width: 300)
    .onAppear {
      name = currentName
      isFocused = true
    }
  }
}

#Preview {
  SettingView()
    .environment(SessionStore.preview)
    .frame(width: 600, height: 700)
}
