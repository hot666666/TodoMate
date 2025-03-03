//
//  StubGroupService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

protocol GroupServiceType {
    func fetch(groupId: String) async -> UserGroup?
    func update(_ group: UserGroup) async
}

class StubGroupService: GroupServiceType {
    func fetch(groupId: String) async -> UserGroup? {
        if groupId == UserGroup.stub.id {
            return UserGroup.stub
        }
        return nil
    }
    
    func update(_ group: UserGroup) async {
        print("[Updating Group - \(group.id)] - ")
    }
}
