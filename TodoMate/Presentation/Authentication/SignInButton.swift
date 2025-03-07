//
//  SignInButton.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct SignInButton: View {
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        Button {
            Task {
                await authManager.signIn()
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
            .environment(AuthManager.stub)
    }
    .frame(width: 300, height: 300)
}

