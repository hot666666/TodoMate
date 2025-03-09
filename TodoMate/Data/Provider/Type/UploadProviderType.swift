//
//  UploadProviderType.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

protocol UploadProviderType {
    func upload(path: String, data: Data, fileName: String) async throws -> String
}

class StubUploadProvider: UploadProviderType {
    func upload(path: String, data: Data, fileName: String) async throws -> String {
        "some-url"
    }
}
