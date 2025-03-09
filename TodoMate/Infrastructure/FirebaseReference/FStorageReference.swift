//
//  FStorageReference.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//


import FirebaseStorage

final class FStorageReference {
    static let shared = FStorageReference()
    let reference = Storage.storage().reference()
    
    private init() {}
}
