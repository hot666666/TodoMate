//
//  SignInButton.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct SignInButton: View {
    @Environment(CurrentUserStore.self) private var currentUserStore
    
    var body: some View {
        Button {
            Task {
                await currentUserStore.signIn()
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
    }
}

#Preview {
    VStack {
        SignInButton()
            .environment(CurrentUserStore())
    }
    .frame(width: 300, height: 300)
}

