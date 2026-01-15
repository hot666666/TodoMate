import FirebaseCore
@preconcurrency import FirebaseFirestore
import Foundation

// MARK: - Firebase Init
func loadFirebaseConfig() {
    let filePath = "./GoogleService-Info.plist"
    guard FileManager.default.fileExists(atPath: filePath),
          let options = FirebaseOptions(contentsOfFile: filePath) else {
        fatalError("GoogleService-Info.plist not found at path: \(filePath)")
    }
    FirebaseApp.configure(options: options)
    print("Firebase Initialized!")
}

// MARK: - Batch Update Function
/// Checks documents in the specified collection and adds 'isDeleted: false' if the field is missing.
func updateMissingIsDeleted(db: Firestore, collectionName: String) async {
    let batchLimit = 500
    print("Starting update for collection: '\(collectionName)'...")

    do {
        // Fetch all documents
        // Note: For very large collections, fetching all at once might be memory intensive.
        // But for a migration script of a typical personal/small-group app, this is usually fine.
        let snapshot = try await db.collection(collectionName).getDocuments()
        let documents = snapshot.documents
        print("Scanned \(documents.count) documents in '\(collectionName)'.")

        // Filter documents that need update
        var docsToUpdate: [QueryDocumentSnapshot] = []

        for doc in documents {
            let data = doc.data()
            // Check if 'isDeleted' key exists
            if data["isDeleted"] == nil {
                docsToUpdate.append(doc)
            }
        }

        print("Found \(docsToUpdate.count) documents missing 'isDeleted'.")

        if docsToUpdate.isEmpty {
            print("No documents need updating.")
            return
        }

        // Batch Process
        for batchStart in stride(from: 0, to: docsToUpdate.count, by: batchLimit) {
            let batch = db.batch()
            let batchEnd = min(batchStart + batchLimit, docsToUpdate.count)
            let currentBatchDocs = docsToUpdate[batchStart..<batchEnd]

            print("Processing batch \(batchStart + 1)-\(batchEnd) of \(docsToUpdate.count)...")

            for doc in currentBatchDocs {
                let docRef = db.collection(collectionName).document(doc.documentID)
                // updateData fails if document doesn't exist, but we know it exists.
                // It merges the data.
                batch.updateData(["isDeleted": false], forDocument: docRef)
            }

            try await batch.commit()
            print("Batch \(batchStart + 1)-\(batchEnd) completed.")
        }

        print("Update for '\(collectionName)' completed successfully!")

    } catch {
        print("Error during update: \(error)")
    }
}

@main
struct Main {
    static func main() async {
        loadFirebaseConfig()
        let db = Firestore.firestore()

        // Target collection: v2-todos
        // Verified from TodoMateData/FirestoreReference.swift
        let targetCollection = "v2-todos"

        await updateMissingIsDeleted(db: db, collectionName: targetCollection)

        print("All migration tasks completed.")
        exit(0)
    }
}
