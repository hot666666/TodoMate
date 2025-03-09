//
//  AuthView.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

struct AuthView: View {
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
    }
}

#Preview {
    AuthView()
        .environment(AuthManager.stub)
}
