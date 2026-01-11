//
//
//  LoginView.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct LoginView: View {
  @Environment(PublicDIContainer.self) private var container
  @State private var isLoading = false
  @State private var isErrorDialogPresented = false
  @State private var errorMessage: String?

  @MainActor
  private func signIn() async {
    defer { isLoading = false }
    isLoading = true
    do {
      try await container.signInUseCase.run()
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
          HStack(spacing: 4) {
            Image(systemName: "g.circle.fill")
              .imageScale(.large)
            Text("Google로 로그인")
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .buttonStyle(GlassmorphismButtonStyle(disabled: isLoading))
        .disabled(isLoading)
      }
    }

    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    .environment(PublicDIContainer.preview)
}
