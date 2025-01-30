//
//  UploadProvider.swift
//  TodoMate
//
//  Created by hs on 9/1/24.
//

import Foundation

protocol UploadProviderType {
    func upload(path: String, data: Data, fileName: String) async throws -> String
}

final class UploadProvider: UploadProviderType {
    let storage: FStorageReference
    
    init(reference: FStorageReference = .shared) {
        self.storage = reference
    }

    func upload(path: String, data: Data, fileName: String) async throws -> String {
        let ref = storage.reference.child(path).child(fileName)
        let _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL().absoluteString
        
        return url
    }
}
