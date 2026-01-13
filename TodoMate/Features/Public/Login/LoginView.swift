//
//
//  LoginView.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct LoginView: View {
  @Environment(AppDIContainer.self) private var appDI
  @State private var isLoading = false
  @State private var isErrorDialogPresented = false
  @State private var errorMessage: String?

  @MainActor
  private func signIn() async {
    defer { isLoading = false }
    isLoading = true
    do {
      try await appDI.pub.signInUseCase.run()
    } catch {
      errorMessage = "로그인에 실패했습니다: \(error.localizedDescription)"
      isErrorDialogPresented = true
    }
  }
}

extension LoginView {
  var body: some View {
    VStack {
      VStack(spacing: 32) {
        Image("AppImage")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 200, maxHeight: 200)

        Button {
          Task {
            await signIn()
          }
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "g.circle.fill")
              .imageScale(.large)
            Text("Google 로그인")
              .font(.headline)
              .fontWeight(.bold)
          }
          .foregroundStyle(.white)
          .padding(.horizontal, 32)
          .padding(.vertical, 14)
          .background(Color.blue)
          .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
      }
    }

    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityIdentifier("loginView")
    .confirmationDialog(
      "로그인 오류",
      isPresented: $isErrorDialogPresented,
      titleVisibility: .visible,
    ) {
      Button("확인") {}
    } message: {
      if let errorMessage {
        Text(errorMessage)
      }
    }
  }
}

#Preview {
  LoginView()
    .environment(AppDIContainer.preview)
}
