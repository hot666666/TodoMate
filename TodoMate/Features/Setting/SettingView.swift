//
//  SettingView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import Common
import SwiftUI
import TodoMateDomain

struct SettingView: View {
  @Environment(AppDIContainer.self) private var appDI
  @Environment(SessionStore.self) private var sessionStore
  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false
  @AppStorage(UserDefaultsKey.showInDock.rawValue)
  private var showInDock: Bool = true
  @AppStorage(UserDefaultsKey.quitOnWindowClose.rawValue)
  private var quitOnWindowClose: Bool = true
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
      VStack(spacing: 30) {
        profileSection
        if sessionStore.user != nil {
          groupSection
        }
        dockSection
      }
      .accessibilityIdentifier("setting_view")
      .padding(32)
      .frame(maxWidth: 500)
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .onAppear {
      if let displayName = sessionStore.user?.displayName {
        appDI.core.sidebarCacheUseCase.saveProfileName(displayName)
      }
    }
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

  // MARK: - Dock Section

  private var dockSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("General")
        .font(.headline)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 12) {
        Toggle("Dock에 앱 표시", isOn: $showInDock)
          .toggleStyle(.checkbox)

        Toggle("창을 닫으면 앱 종료", isOn: $quitOnWindowClose)
          .toggleStyle(.checkbox)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .onChange(of: showInDock) { _, newValue in
      NSApp.updateActivationPolicy(showInDock: newValue, activate: true)
    }
  }

  // MARK: - Profile Section

  private var profileSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("User")
        .font(.headline)
        .foregroundStyle(.secondary)

      Group {
        if let user = sessionStore.user {
          UserProfile(
            displayName: user.displayName,
            style: .default,
            size: 64,
          ) {
            Button("로그아웃") {
              showLogoutConfirmation = true
            }
            .foregroundStyle(.red)
            .buttonStyle(.plain)
          } trailingAction: {
            Button("수정") {
              editingName = user.displayName
              showEditNameSheet = true
            }
            .buttonStyle(.bordered)
            .disabled(!isPublicModeEnabled)
          }
        } else {
          UserProfile(displayName: "TodoMate", style: .default) {
            Image("AppImage")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 64, height: 64)
              .clipShape(Circle())
          } leadingAction: {
            Button {
              Task {
                try? await appDI.pub.signInUseCase.run()
              }
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "g.circle.fill")
                Text("로그인")
              }
              .foregroundStyle(.white)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color.blue)
              .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
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
            Image(systemName: "person.2.fill")
              .font(.system(size: 24))
              .foregroundStyle(DesignSystem.Colors.accentIndigo)
              .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
              Text(sessionStore.currentGroup?.name ?? "My Group")
                .font(.subheadline)
                .fontWeight(.medium)
              Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Leave Group (Moved from below)
            Button {
              showLeaveGroupConfirmation = true
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Leave")
              }
              .foregroundStyle(.red)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color.red.opacity(isPublicModeEnabled ? 0.1 : 0.05))
              .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!isPublicModeEnabled)
          }
          .padding(16)
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
    }
  }

  // MARK: - Actions

  private func updateDisplayName(_ newName: String) async {
    guard var user = sessionStore.user else { return }
    user.displayName = newName
    user.updatedAt = Date()

    do {
      try await sessionStore.updateUser(user)
      appDI.core.sidebarCacheUseCase.saveProfileName(newName)
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
