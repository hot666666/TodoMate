//
//  Profile.swift
//  TodoMate
//
//  Created by hs on 1/29/25.
//

import SwiftUI

struct ProfileSheetView: View {
    let user: User
    let updateGroup: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(user.nickname)
                .font(.largeTitle)
            
            Button {
                Task {
                    await updateGroup()
                }
            } label: {
                Text("그룹 최신화")
            }
            
            SignOutButton()
        }
    }
}

#Preview {
    ProfileSheetView(user: User.stub[0], updateGroup: {})
        .environment(AuthManager.signedInAndHasGroupStub)
        .frame(width: 400, height: 400)
}
