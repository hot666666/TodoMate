//
//  AuthView.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct AuthView: View {
  @Environment(AuthManager.self) private var authManager

  var body: some View {
    VStack {
      Spacer()

      VStack {
        Image("AppImage")
          .resizable()
          .aspectRatio(contentMode: .fit)

        SignInButton()
          .padding(.bottom)
      }
    }
    .frame(width: 400, height: 400)
    .alert(
      "Error",
      isPresented: Bindable(authManager).showPopup,
      presenting: authManager.errorLog
    ) { _ in
      Button("OK") {
        authManager.closePopup()
      }
    } message: { message in
      Text(message)
    }
  }
}

#Preview {
  AuthView()
    .environment(AuthManager.stub)
}
