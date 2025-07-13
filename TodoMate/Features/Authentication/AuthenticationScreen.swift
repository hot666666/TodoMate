//
//
//  AuthenticationScreen.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct AuthenticationScreen: View {
  @Environment(DIContainer.self) private var container
  @State private var isLoading = false

  var body: some View {
    VStack {
      VStack {
        Image("AppImage")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 200, maxHeight: 200)

        Button {
          Task {
            isLoading = true
            try? await container.signInUseCase.run()
            isLoading = false
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
        .disabled(isLoading)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  AuthenticationScreen()
    .environment(DIContainer.preview)
}
