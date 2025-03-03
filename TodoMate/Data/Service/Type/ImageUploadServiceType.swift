//
//  StubImageUploadService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

protocol ImageUploadServiceType {
    func upload(data: Data) async -> String  /// URL
}

class StubImageUploadService: ImageUploadServiceType {
    func upload(data: Data) async -> String {
        ""
    }
}
