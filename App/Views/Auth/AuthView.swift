//
//  AuthView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct AuthView: View {
  @Environment(AppDependencies.self) var dependencies
  @State private var isSigningIn = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 80))
        .foregroundStyle(DesignSystem.Colors.primary)
        .symbolEffect(.bounce, value: isSigningIn)

      VStack(spacing: 8) {
        Text("Welcome to TodoMate")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(.primary)

        Text("Organize your life with ease.")
          .font(.body)
          .foregroundStyle(.secondary)
      }

      if let errorMessage {
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(DesignSystem.Colors.trafficRed)
          .multilineTextAlignment(.center)
      }

      Button {
        signIn()
      } label: {
        HStack {
          if isSigningIn {
            ProgressView()
              .controlSize(.small)
          } else {
            Text("Get Started")
          }
        }
        .frame(minWidth: 120)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
      }
      .buttonStyle(.borderedProminent)
      .tint(DesignSystem.Colors.primary)
      .disabled(isSigningIn)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.backgroundLight)
  }

  private func signIn() {
    isSigningIn = true
    errorMessage = nil

    Task {
      do {
        try await dependencies.authManager.signInAnonymously()
      } catch {
        errorMessage = "Failed to sign in: \(error.localizedDescription)"
        isSigningIn = false
      }
    }
  }
}

#Preview {
  AuthView()
    .environment(AppDependencies())
}
