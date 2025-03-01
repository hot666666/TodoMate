//
//  SignOutButton.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct SignOutButton: View {
    @Environment(CurrentUserStore.self) private var currentUserStore
    
    var body: some View {
        Button("로그아웃", role: .destructive) {
            Task {
                await currentUserStore.signOut()
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    SignOutButton()
        .environment(CurrentUserStore())
}

