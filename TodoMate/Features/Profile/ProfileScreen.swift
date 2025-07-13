//
//  ProfileScreen.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct ProfileScreen: View {
  @Environment(SessionStore.self) private var sessionStore

  var body: some View {
    VStack {
      Button("로그아웃") {
        sessionStore.signOut()
      }
    }
    .padding()
  }
}

#Preview {
  ProfileScreen()
    .environment(SessionStore.preview)
}
