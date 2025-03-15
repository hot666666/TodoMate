//
//  FirestoreMessageStreamProvider.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//


final class FirestoreMessageStreamProvider: MessageStreamProviderType {
	private let reference: FirestoreReference
	
	init(reference: FirestoreReference = .shared) {
		self.reference = reference
	}
}

extension FirestoreMessageStreamProvider {
#if !PREVIEW
	func createMessageStream() -> AsyncStream<DatabaseChange<MessageModel>> {
		AsyncStream { continuation in
      let listener = reference.messageCollection()
				.addSnapshotListener { querySnapshot, error in
					guard let snapshot = querySnapshot else {
						if let error = error {
							print("Error fetching snapshots: \(error)")
						}
						return
					}
					
					snapshot.documentChanges.forEach { diff in
						if let messageDTO = try? diff.document.data(as: MessageDTO.self),
							 let message = MessageModel.from(messageDTO) {
							switch diff.type {
							case .added:
								continuation.yield(.added(message))
							case .modified:
								continuation.yield(.modified(message))
							case .removed:
								continuation.yield(.removed(message))
							}
						} else {
							print("Failed to decode document with ID: \(diff.document.documentID)")
						}
					}
				}
			
			continuation.onTermination = { @Sendable _ in
				print("[FirestoreMessageStreamProvider] - Stream Terminated")
				/// 스트림이 종료될 때 리스너 해제
				listener.remove()
			}
		}
	}
#else
	func createMessageStream() -> AsyncStream<DatabaseChange<MessageModel>> {
		AsyncStream { continuation in
			print("[FirestoreMessageStreamProvider] - Stream Created")
			
			for message in MessageModel.stubs {
				continuation.yield(.added(message))
			}
			
			let task = Task {
				while !Task.isCancelled {
					do {
						try await Task.sleep(nanoseconds: 10_000_000_000)
					} catch {
						// 취소 에러 발생 시 루프 종료
						print("[FirestoreMessageStreamProvider] - Listening error")
						break
					}
				}
			}
			
			continuation.onTermination = { @Sendable _ in
				print("[FirestoreMessageStreamProvider] - Stream Terminated")
				task.cancel()
			}
		}
	}
#endif
}
