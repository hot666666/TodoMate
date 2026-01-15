//
//  GroupRepositoryError.swift
//  TodoMateData
//
//  Created by agent on 1/15/26.
//

import Foundation

/// Data 계층 Group Repository 에러
public enum GroupRepositoryError: Error {
  case groupNotFound(groupId: String)
  case alreadyMember(userId: String)
}
