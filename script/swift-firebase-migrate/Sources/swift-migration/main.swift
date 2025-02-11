import Foundation
import FirebaseCore
import FirebaseFirestore

struct TodoDTO: Codable {
    @DocumentID var id: String?
    var content: String
    var status: String
    var detail: String
    var date: Date
    var uid: String
}

// GoogleService-Info.plist 로드 함수
func loadFirebaseConfig() {
    let filePath = "./GoogleService-Info.plist"
    guard FileManager.default.fileExists(atPath: filePath),
          let options = FirebaseOptions(contentsOfFile: filePath) else {
        fatalError("GoogleService-Info.plist 파일을 찾을 수 없습니다.")
    }
    FirebaseApp.configure(options: options)
    print("Firebase Initialized!")
}

func migrateTodoUID() async {
    let db = Firestore.firestore()
    let batchLimit = 500 // Firestore 배치 작업 제한

    let FROM_USER1 = "uid1"
    let FROM_USER2 = "uid2"
    let TO_USER1 = "new-uid1"
    let TO_USER2 = "new-uid2"

    print("Migration started...")
    do {
        let snapshot = try await db.collection("todos").getDocuments()
        let todos: [TodoDTO] = snapshot.documents.compactMap { try? $0.data(as: TodoDTO.self) }
        print("총 \(todos.count)개의 Todo 존재")
        
        for batchStart in stride(from: 0, to: todos.count, by: batchLimit) {
            // 배치 작업 시작
            let batch = db.batch()
            let batchEnd = min(batchStart + batchLimit, todos.count)
            let currentBatch = Array(todos[batchStart..<batchEnd])
            
            print("Processing batch \(batchStart)-\(batchEnd) of \(todos.count)")
            
            for var todo in currentBatch {
                if todo.uid == TO_USER1 || todo.uid == TO_USER2 {
                    print("\(todo.uid) - \(todo.content), 업데이트 필요 없음")
                    continue
                }
                
                let before = todo.uid
                if todo.uid == FROM_USER1 { todo.uid = TO_USER1 } 
                else if todo.uid == FROM_USER2 { todo.uid = TO_USER2 }
                print("\(before) -> \(todo.uid)")
                
                if let id = todo.id {
                    try batch.setData(from: todo, forDocument: db.collection("todos").document(id))
                }
            }
            
            // 현재 배치 커밋
            try await batch.commit()
            print("Batch \(batchStart)-\(batchEnd) completed")
        }
    } catch {
        print("Error during migration: \(error)")
    }
    print("Migration completed!")
}

@main
struct Main {
    static func main() async {
        loadFirebaseConfig()

        await migrateTodoUID()

        exit(0) 
    }
}