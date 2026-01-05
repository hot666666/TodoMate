//
//  SettingsView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct SettingsView: View {
  @Environment(SessionStore.self) private var sessionStore
  @State private var showLogoutConfirmation = false
  @State private var showLeaveGroupConfirmation = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Profile Section
        profileSection

        // Group Section
        groupSection

        // Account Section
        accountSection
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
      Text(
        "Are you sure you want to leave \"Design Team\"? You'll need an invitation to rejoin.",
      )
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
  }

  // MARK: - Profile Section

  private var profileSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Profile")
        .font(.headline)
        .foregroundStyle(.secondary)

      HStack(spacing: 16) {
        // Avatar
        Circle()
          .fill(
            LinearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing,
            ),
          )
          .frame(width: 64, height: 64)
          .overlay(
            Text(sessionStore.user.displayName.prefix(2).uppercased())
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundStyle(.white),
          )

        VStack(alignment: .leading, spacing: 4) {
          Text(sessionStore.user.displayName)
            .font(.title3)
            .fontWeight(.semibold)
          Text("user@example.com")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button("Edit") {
          // Edit profile
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
        // Current Group
        HStack(spacing: 12) {
          Image(systemName: "person.3.fill")
            .font(.system(size: 24))
            .foregroundStyle(.blue)
            .frame(width: 40)

          VStack(alignment: .leading, spacing: 2) {
            Text("Design Team")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("4 members")
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
      }
      .background(Color(nsColor: .controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  // MARK: - Account Section

  private var accountSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Account")
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
}

#Preview {
  SettingsView()
    .environment(SessionStore.preview)
    .frame(width: 600, height: 700)
}
