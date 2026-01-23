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
  // MARK: - Environment

  @Environment(AppDIContainer.self) private var appDI
  @Environment(SessionStore.self) private var sessionStore

  // MARK: - AppStorage

  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false
  @AppStorage(UserDefaultsKey.showInDock.rawValue)
  private var showInDock: Bool = true
  @AppStorage(UserDefaultsKey.quitOnWindowClose.rawValue)
  private var quitOnWindowClose: Bool = true

  // MARK: - State

  @State private var showLogoutConfirmation = false
  @State private var showLeaveGroupConfirmation = false
  @State private var showEditNameSheet = false
  @State private var editingName = ""

  // MARK: - Body

  var body: some View {
    ScrollView {
      VStack(spacing: 30) {
        profileSection
        if let user = sessionStore.user {
          groupSection
          LegacyImportSection(
            user: user,
            importLegacyDataUseCase: appDI.importLegacyDataUseCase,
          )
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
    .onAppear(perform: onAppear)
    .confirmationDialog(
      "그룹 나가기",
      isPresented: $showLeaveGroupConfirmation,
      titleVisibility: .visible,
    ) {
      Button("나가기", role: .destructive) {
        Task { await sessionStore.leaveGroup() }
      }
      Button("취소", role: .cancel) {}
    } message: {
      Text("그룹을 나가시겠습니까?")
    }
    .confirmationDialog(
      "로그아웃",
      isPresented: $showLogoutConfirmation,
      titleVisibility: .visible,
    ) {
      Button("로그아웃", role: .destructive) {
        sessionStore.signOut()
      }
      Button("취소", role: .cancel) {}
    } message: {
      Text("로그아웃 하시겠습니까?")
    }
    .sheet(isPresented: $showEditNameSheet) {
      EditDisplayNameSheet(
        currentName: sessionStore.user?.displayName ?? "",
        onSave: { newName in
          Task { await updateDisplayName(newName) }
        },
      )
    }
  }

  // MARK: - Components

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

  private var groupSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Group")
        .font(.headline)
        .foregroundStyle(.secondary)

      VStack(spacing: 0) {
        if !sessionStore.userGroupId.isEmpty {
          currentGroupView
        } else {
          noGroupView
        }
      }
    }
  }

  private var currentGroupView: some View {
    HStack(spacing: 12) {
      Image(systemName: "person.2.fill")
        .font(.system(size: 24))
        .foregroundStyle(DesignSystem.Colors.accentIndigo)
        .frame(width: 40)

      VStack(alignment: .leading, spacing: 2) {
        Text(sessionStore.currentGroup?.name ?? "My Group")
          .font(.subheadline)
          .fontWeight(.medium)
        let count = sessionStore.groupMembers.count
        Text("\(count) member\(count == 1 ? "" : "s")")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

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
  }

  private var noGroupView: some View {
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

  // MARK: - Actions

  private func onAppear() {
    if let displayName = sessionStore.user?.displayName {
      appDI.core.sidebarCacheUseCase.saveProfileName(displayName)
    }
  }

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

#Preview {
  SettingView()
    .environment(SessionStore.preview)
    .environment(AppDIContainer.preview)
    .frame(width: 600, height: 700)
}
