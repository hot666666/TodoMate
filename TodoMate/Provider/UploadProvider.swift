//
//  UploadProvider.swift
//  TodoMate
//
//  Created by hs on 9/1/24.
//


import Foundation
import FirebaseStorage

enum UploadError: Error {
    case error(Error)
}

protocol UploadProviderType {
    func upload(path: String, data: Data, fileName: String) async throws -> String
}

class UploadProvider: UploadProviderType {
    
    let storageRef = Storage.storage().reference()
    
    func upload(path: String, data: Data, fileName: String) async throws -> String {
        let ref = storageRef.child(path).child(fileName)
        let _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL().absoluteString
        
        return url
    }
}
