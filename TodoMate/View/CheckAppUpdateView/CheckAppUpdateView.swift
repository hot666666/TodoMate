//
//  CheckAppUpdateView.swift
//  TodoMate
//
//  Created by hs on 8/24/24.
//

import SwiftUI
import FirebaseStorage

struct CheckAppUpdateView: View {
    @State private var isUpdateAvailable: Bool = false
    @State private var latestVersion: String = ""
    @State private var isDownloading: Bool = false
    @State private var downloadProgress: Double = 0.0
    
    var body: some View {
        VStack {
            Spacer()
            if latestVersion <= currentAppVersion {
                Text("현재 최신 버전입니다")
            } else {
                Text("현재 버전 : \(currentAppVersion)")
            }
            
            if isUpdateAvailable {
                Button(action: downloadLatestUpdate) {
                    Text("TodoMate \(latestVersion) 다운로드")
                }
            } else {
                Button(action: checkForUpdate) {
                    Text("업데이트 확인")
                }
            }
            
            if isDownloading {
                ProgressView(value: downloadProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .padding()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: openDocumentsFolder) {
                    Image(systemName: "folder.fill")
                }
                .hoverButtonStyle()
            }
        }
        .frame(width: 300, height: 400)
        .padding()
        .onAppear {
            checkForUpdate()
        }
    }
    
    private var currentAppVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func openDocumentsFolder() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        NSWorkspace.shared.open(documentsPath)
    }
    
    private func checkForUpdate() {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        storageRef.listAll { (result, error) in
            if let error = error {
                print("Error fetching file list: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else { return }
            
            let versions = result.items.compactMap { extractVersion(from: $0.name) }
            guard let maxVersion = versions.max() else { return }
            
            self.latestVersion = maxVersion
            self.isUpdateAvailable = maxVersion > currentAppVersion
        }
    }
    
    private func extractVersion(from fileName: String) -> String? {
        let pattern = #"(?i)todomate\s+(\d+(?:\.\d+)*)\.zip"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            if let match = regex.firstMatch(in: fileName, options: [], range: NSRange(location: 0, length: fileName.utf16.count)) {
                if let versionRange = Range(match.range(at: 1), in: fileName) {
                    return String(fileName[versionRange])
                } else {
                    print("버전 범위를 찾을 수 없습니다.")
                }
            } else {
                print("매치를 찾을 수 없습니다. 파일명: \(fileName)")
            }
        } catch {
            print("정규식 에러: \(error)")
        }
        return nil
    }
    
    private func downloadLatestUpdate() {
        isDownloading = true
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let latestFileRef = storageRef.child("TodoMate \(latestVersion).zip")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent(latestFileRef.name)
        
        let downloadTask = latestFileRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
            } else {
                print("File downloaded successfully to: \(localURL.path)")
            }
            self.isDownloading = false
            self.downloadProgress = 0.0
            openDocumentsFolder()
        }
        
        downloadTask.observe(.progress) { snapshot in
            self.downloadProgress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
        }
    }
}
