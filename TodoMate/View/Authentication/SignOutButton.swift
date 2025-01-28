//
//  SignOutButton.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct SignOutButton: View {
    @Environment(AuthManager.self) private var authViewModel
    
    var body: some View {
        Button("로그아웃", role: .destructive) {
            Task {
                await authViewModel.signOut()
            }
        }
        .buttonStyle(.borderedProminent)
    }
}


#Preview {
    SignOutButton()
        .environment(AuthManager(userService: StubUserService(),
                                 userInfoService: StubUserInfoService(),
                                 modelContainer: .forPreview()))
}

