import FirebaseCore
@preconcurrency import FirebaseFirestore
import Foundation

// MARK: - 기존 DTO 정의 (Firestore 데이터 읽기용)

struct UserDTO: Codable, Sendable {
    @DocumentID var id: String?
    var nickname: String
    var gid: String?
}

struct TodoDTO: Codable, Sendable {
    @DocumentID var id: String?
    var content: String
    var status: String
    var detail: String
    var date: Date
    var uid: String
    var lastModifiedAt: Date
}

struct ChatDTO: Codable, Sendable {
    @DocumentID var id: String?
    var content: String
    var lastModifiedUser: String
    var date: Date
    var isImage: Bool
}

struct MessageDTO: Codable, Sendable {
    @DocumentID var id: String?
    var content: String
    var lastModifiedUser: String
    let createdAt: Date
    let lastModifiedAt: Date
}


// MARK: - 신규 엔티티 정의 (Firestore 데이터 쓰기용)

struct User: Codable, Identifiable, Sendable {
    let id: String
    var displayName: String
    var groupId: String
    let createdAt: Date
    var updatedAt: Date
}

enum TodoStatus: String, CaseIterable, Codable, Sendable {
    case inComplete = "미완료"
    case todo = "시작 전"
    case inProgress = "진행 중"
    case complete = "완료"
}

struct Todo: Identifiable, Codable, Sendable {
    let id: String
    var content: String
    var status: TodoStatus
    var detail: String
    var date: Date
    let createdAt: Date
    var updatedAt: Date
    let owner: String
}

struct GroupMessage: Identifiable, Codable, Sendable {
    let id: String
    var content: String
    let groupId: String
    let owner: String
    let createdAt: Date
    var updatedAt: Date
}

struct Memo: Identifiable, Codable, Sendable {
    let id: String
    var content: String
    let createdAt: Date
    var updatedAt: Date
    let owner: String
}

// MARK: - Firebase 초기화

func loadFirebaseConfig() {
    let filePath = "./GoogleService-Info.plist"
    guard FileManager.default.fileExists(atPath: filePath),
          let options = FirebaseOptions(contentsOfFile: filePath) else {
        fatalError("GoogleService-Info.plist 파일을 찾을 수 없습니다.")
    }
    FirebaseApp.configure(options: options)
    print("Firebase Initialized!")
}

// MARK: - 마이그레이션 함수

/// Firestore 문서를 읽어 새로운 컬렉션에 배치 처리하는 헬퍼 함수
func processAndCopyToV2<T: Codable & Sendable, U: Codable & Sendable>(
    db: Firestore,
    sourceCollection: String,
    destinationCollection: String,
    transform: @Sendable (T) throws -> (String, U)
) async {
    let batchLimit = 500
    print("Migration from '\(sourceCollection)' to '\(destinationCollection)' started...")

    do {
        let snapshot = try await db.collection(sourceCollection).getDocuments()
        let documents: [T] = snapshot.documents.compactMap { try? $0.data(as: T.self) }
        print("총 \(documents.count)개의 문서를 '\(sourceCollection)' 컬렉션에서 발견했습니다.")

        for batchStart in stride(from: 0, to: documents.count, by: batchLimit) {
            let batch = db.batch()
            let batchEnd = min(batchStart + batchLimit, documents.count)
            let currentBatchDocs = Array(documents[batchStart..<batchEnd])

            print("Processing batch \(batchStart + 1)-\(batchEnd) of \(documents.count)")

            for docData in currentBatchDocs {
                let (docId, transformedData) = try transform(docData)
                let docRef = db.collection(destinationCollection).document(docId)
                try batch.setData(from: transformedData, forDocument: docRef)
            }

            try await batch.commit()
            print("Batch \(batchStart + 1)-\(batchEnd) completed.")
        }
        print("Migration to '\(destinationCollection)' completed successfully!")
    } catch {
        print("Error during migration from '\(sourceCollection)' to '\(destinationCollection)': \(error)")
    }
}


@main
struct Main {
    static func main() async {
        loadFirebaseConfig()
        let db = Firestore.firestore()

        // --- User 마이그레이션: users -> v2-users ---
        await processAndCopyToV2(db: db, sourceCollection: "users", destinationCollection: "v2-users") { (dto: UserDTO) -> (String, User) in
            guard let id = dto.id else { throw NSError(domain: "Missing ID", code: -1) }
            let now = Date()
            let user = User(
                id: id,
                displayName: dto.nickname,
                groupId: dto.gid ?? UUID().uuidString, // gid가 nil이면 새로운 그룹 ID 생성
                createdAt: now,
                updatedAt: now
            )
            return (id, user)
        }

        // --- Todo 마이그레이션: todos -> v2-todos ---
        await processAndCopyToV2(db: db, sourceCollection: "todos", destinationCollection: "v2-todos") { (dto: TodoDTO) -> (String, Todo) in
            guard let id = dto.id else { throw NSError(domain: "Missing ID", code: -1) }
            let todo = Todo(
                id: id,
                content: dto.content,
                status: TodoStatus(rawValue: dto.status) ?? .todo,
                detail: dto.detail,
                date: dto.date,
                createdAt: dto.lastModifiedAt, // createdAt은 lastModifiedAt으로 초기화
                updatedAt: dto.lastModifiedAt,
                owner: dto.uid
            )
            return (id, todo)
        }
        
        // --- Message -> Memo 마이그레이션: messages -> v2-memos ---
        await processAndCopyToV2(
            db: db, sourceCollection: "messages", destinationCollection: "v2-memos"
        ) { (dto: MessageDTO) -> (String, Memo) in
            guard let id = dto.id else { throw NSError(domain: "Missing ID", code: -1) }
            let memo = Memo(
                id: id,
                content: dto.content,
                createdAt: dto.createdAt,
                updatedAt: dto.lastModifiedAt,
                owner: dto.lastModifiedUser
            )
            return (id, memo)
        }

        // --- Chat -> GroupMessage 마이그레이션: chats -> v2-group_messages ---
        await processAndCopyToV2(
            db: db, sourceCollection: "chats", destinationCollection: "v2-group_messages"
        ) { (dto: ChatDTO) -> (String, GroupMessage) in
            guard let id = dto.id else { throw NSError(domain: "Missing ID", code: -1) }
            
            // Chat 마이그레이션에서는 groupId를 찾아야 하지만, 여기서는 우선 nil-coalescing으로 처리합니다.
            // 더 정확한 마이그레이션을 위해서는 User 데이터를 먼저 조회해야 합니다.
            let groupMessage = GroupMessage(
                id: id,
                content: dto.content,
                groupId: "NEEDS_MIGRATION", // 임시값, 실제 마이그레이션 시 User 정보에서 찾아야 함
                owner: dto.lastModifiedUser,
                createdAt: dto.date,
                updatedAt: dto.date
            )
            return (id, groupMessage)
        }


        print("All migration tasks completed!")
        exit(0)
    }
}
