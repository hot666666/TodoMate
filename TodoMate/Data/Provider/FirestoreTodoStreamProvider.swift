//
//  FirestoreTodoStreamProvider.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//

import Foundation

enum FirestoreTodoStreamProviderError: Error {
  case decodingFailed(String)
  case conversionFailed(String)
}

final class FirestoreTodoStreamProvider: TodoStreamProviderType {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
    self.reference = reference
  }
}

extension FirestoreTodoStreamProvider {
  // TODO: - 그룹 유저에 대해 Todo 필터작업 필요
  #if !PREVIEW
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
      AsyncStream { continuation in
        let streamCreatedTime: Date = .now

        let listener = reference.todoCollection()
        #if DEBUG
          /// whereField는 해당 조건에 맞는 데이터에 대해서만 업데이트를 처리하지만, 이 조건 밖의 데이터가 이 조건에 맞게 변경되어도 업데이트를 처리하지
          /// 않는다
          /// 앱이 초기화 된 상태에서는 다시 데이터를 전부 불러오기 때문에 3일 전 데이터까지만 불러온다
          .whereField(
            "date",
            isGreaterThanOrEqualTo: streamCreatedTime.addingTimeInterval(-60 * 60 * 24 * 3)
          )
        #endif
          .addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
              if let error = error {
                print("[FirestoreTodoStreamProvider] - Error fetching snapshots: \(error)")
              }
              return
            }

            for diff in snapshot.documentChanges {
              do {
                // 디코딩
                guard let todoDTO = try? diff.document.data(as: TodoDTO.self) else {
                  throw FirestoreTodoStreamProviderError
                    .decodingFailed("문서 데이터를 TodoDTO로 디코딩 실패: \(diff.document.documentID)")
                }

                // 타임스탬프 검증
                guard todoDTO.lastModifiedAt >= streamCreatedTime else {
                  continue
                }

                // 모델 변환
                guard let todo = try? todoDTO.toModel() else {
                  throw FirestoreTodoStreamProviderError
                    .conversionFailed("TodoDTO를 Todo 모델로 변환 실패: \(diff.document.documentID)")
                }

                switch diff.type {
                case .added:
                  continuation.yield(.added(todo))
                case .modified:
                  continuation.yield(.modified(todo))
                case .removed:
                  continuation.yield(.removed(todo))
                }
              } catch let FirestoreTodoStreamProviderError.decodingFailed(message) {
                print("[FirestoreTodoStreamProvider] - 디코딩 오류: \(message)")
              } catch let FirestoreTodoStreamProviderError.conversionFailed(message) {
                print("[FirestoreTodoStreamProvider] - 변환 오류: \(message)")
              } catch {
                print("[FirestoreTodoStreamProvider] - 예상치 못한 오류 발생: \(error.localizedDescription)")
              }
            }
          }

        continuation.onTermination = { @Sendable _ in
          /// 스트림이 종료될 때 리스너 해제
          print("[FirestoreTodoStreamProvider] - Stream Terminated")
          listener.remove()
        }
      }
    }
  #else
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
      AsyncStream { continuation in
        let stream = self.reference.db.todoStream()
        let task = Task {
          for await change in stream {
            if let todo = try? change.data.toModel() {
              switch change {
              case .added:
                continuation.yield(.added(todo))
              case .modified:
                continuation.yield(.modified(todo))
              case .removed:
                continuation.yield(.removed(todo))
              }
            } else {
              print("Error decoding and converting todo: \(change.data)")
            }
          }
        }

        continuation.onTermination = { @Sendable _ in
          print("[FirestoreTodoStreamProvider] - Stream Terminated")
          task.cancel()
          self.reference.db.todoStreamTermination()
        }
      }
    }
  #endif
}
