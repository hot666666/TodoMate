//
//  ImageUploadService.swift
//  TodoMate
//
//  Created by hs on 9/1/24.
//

import Foundation

class ImageUploadService: ImageUploadServiceType {
    private let provider: UploadProviderType
    
    init(provider: UploadProviderType = UploadProvider()) {
        self.provider = provider
    }
    
    func upload(data: Data) async -> String {
        do {
            return try await provider.upload(path: "images", data: data, fileName: UUID().uuidString)
        } catch {
            print("[Upload Error]")
            return ""
        }
    }
}
