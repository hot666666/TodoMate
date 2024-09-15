//
//  FirebaseRepositoryError.swift
//  TodoMate
//
//  Created by hs on 9/3/24.
//

import Foundation

enum FirebaseRepositoryError: Error {
    case encodingError
    case decodingError
    case setValueError
    case removeValueError
    case invalidSnapshotError
}
