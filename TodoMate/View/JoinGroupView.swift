//
//  JoinGroupView.swift
//  TodoMate
//
//  Created by hs on 1/29/25.
//

import SwiftUI

struct JoinGroupView: View {
    @Environment(DIContainer.self) private var container
    @Environment(AuthManager.self) private var authManager
    
    @State private var gid: String = ""
    @State private var isJoinButtonEnabled = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let buttonCooldown: TimeInterval = 5
    private let maxLength = 20
    
    var body: some View {
        VStack(spacing: 20) {
            Text("그룹 설정")
                .font(.title)
                .fontWeight(.bold)
            
            // TODO: - 한글 마지막 글자 씹힘
            TextField("Enter Group ID", text: $gid)
                .onChange(of: gid) {
                    if $1.count > maxLength {
                        gid = String($1.prefix(maxLength))
                    }
                }
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await handleJoinGroup()
                }
            }) {
                Text("등록하기")
            }
            .disabled(!isJoinButtonEnabled || gid.isEmpty)
            .padding(.horizontal)
        }
        .padding()
        .alert("그룹 설정", isPresented: $showAlert) {
            Button("확인") { }
        } message: {
            Text(alertMessage)
        }
    }
}
extension JoinGroupView {
    @MainActor
    private func handleJoinGroup() async {
        isJoinButtonEnabled = false
        print(gid)
        
        defer {
            /// 5초 후에 버튼 다시 활성화
            Task {
                try? await Task.sleep(nanoseconds: UInt64(buttonCooldown * 1_000_000_000))
                isJoinButtonEnabled = true
            }
        }
        
        do {
            try await joinGroup()
        } catch {
            alertMessage = "그룹을 등록하는데 실패했습니다."
            showAlert = true
        }
    }
    
    @MainActor
    private func joinGroup() async throws {
        guard var group = await container.groupService.fetch(groupId: gid) else {
            throw NSError(domain: "GroupNotFound", code: 404)
        }
        
        guard var user = await container.userService.fetch(uid: authManager.authenticatedUser.uid) else {
            throw NSError(domain: "UserNotFound", code: 404)
        }
        
        // TODO: - 업데이트 성공에 대한 순차성 보장
        if !group.uids.contains(authManager.authenticatedUser.uid) {
            group.uids.append(authManager.authenticatedUser.uid)
            await container.groupService.update(group)
        }
        
        if user.gid != group.id {
            user.gid = group.id
            await container.userService.update(user)
        }
        
        authManager.updateUserGroup(group.id)
    }
}

#Preview {
    JoinGroupView()
        .environment(DIContainer.stub)
        .environment(AuthManager.stub)
        .frame(width: 400, height: 400)
}
