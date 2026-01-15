//
//  GroupError.swift
//  TodoMateDomain
//
//  Created by hs on 1/16/26.
//

public enum CreateGroupError: Error {
  case userNotFound
}

public enum JoinGroupError: Error {
  case groupNotFound
  case alreadyMember
}

public enum LeaveGroupError: Error {
  case groupNotFound
  case notMember
}
