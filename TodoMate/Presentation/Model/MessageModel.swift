//
//  MessageModel.swift
//  TodoMate
//
//  Created by hs on 3/13/25.
//

import SwiftUI

@Observable
class MessageModel: Identifiable {
	let id: String = UUID().uuidString
	var content: String
	var lastModifiedUser: String
	let createdAt: Date
	var lastModifiedAt: Date
	let fid: String
	
	init(content: String = "", lastModifiedUser: String, createdAt: Date = .now, lastModifiedAt: Date = .now, fid: String) {
		self.content = content
		self.lastModifiedUser = lastModifiedUser
		self.createdAt = createdAt
		self.lastModifiedAt = lastModifiedAt
		self.fid = fid
	}
}

extension MessageModel {
	static func from(_ dto: MessageDTO) -> MessageModel? {
		guard let fid = dto.id else { return nil }
		return MessageModel(content: dto.content, lastModifiedUser: dto.lastModifiedUser, createdAt: dto.createdAt, lastModifiedAt: dto.lastModifiedAt, fid: fid)
	}
}

extension MessageModel {
	static let stub: MessageModel = .init(content: "Hello", lastModifiedUser: "hs", createdAt: .now, lastModifiedAt: .now, fid: "fid1")
	static let stubs: [MessageModel] = [.stub,
																			.init(content: "Hi", lastModifiedUser: "hs", createdAt: .now, lastModifiedAt: .now, fid: "fid2"),
																			.init(content: "Hey", lastModifiedUser: "hs", createdAt: .now, lastModifiedAt: .now, fid: "fid3")]
	
}
