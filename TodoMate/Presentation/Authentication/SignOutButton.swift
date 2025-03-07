//
//  SignOutButton.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct SignOutButton: View {
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        Button("로그아웃", role: .destructive) {
            Task {
                await authManager.signOut()
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    SignOutButton()
        .environment(AuthManager.stub)
}

