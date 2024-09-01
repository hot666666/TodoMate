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
            }
            Text("현재 버전 : \(currentAppVersion)")
            
            if isUpdateAvailable {
                Button(action: downloadLatestUpdate) {
                    Text("TodoMate \(latestVersion) 다운로드")
                        .disabled(isDownloading)
                        .opacity(isDownloading ? 0.3 : 1)
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
        }
        .frame(width: 300, height: 400)
        .padding()
        .onAppear {
            checkForUpdate()
        }
    }
}

extension CheckAppUpdateView {
    private var currentAppVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
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
            
            let versions = result.items.compactMap { Util.extractVersion(from: $0.name) }
            guard let maxVersion = versions.max() else { return }
            
            self.latestVersion = maxVersion
            self.isUpdateAvailable = maxVersion > currentAppVersion
        }
    }
    
    private func downloadLatestUpdate() {
        isDownloading = true
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let latestFileRef = storageRef.child("TodoMate \(latestVersion).zip")
        
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let localURL = downloadsURL.appendingPathComponent(latestFileRef.name)
        
        let downloadTask = latestFileRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
            } else {
                print("File downloaded successfully to: \(localURL.path)")
                
            }
            self.isDownloading = false
            self.downloadProgress = 0.0
            self.unzip(at: localURL)
        }
        
        downloadTask.observe(.progress) { snapshot in
            self.downloadProgress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
        }
    }
    
    private func unzip(at zipURL: URL) {
        let fileManager = FileManager.default
        let unzipDestination = zipURL.deletingLastPathComponent().appendingPathComponent("TodoMate \(latestVersion)")
        
        do {
            try fileManager.createDirectory(at: unzipDestination, withIntermediateDirectories: true, attributes: nil)
            try Util.unzipItem(at: zipURL, to: unzipDestination)
            
            Util.openFolder(at: unzipDestination)
        } catch {
            print("Error during unzip or installation: \(error.localizedDescription)")
        }
    }
    
    private func openDownloadsFolder() {
        if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            Util.openFolder(at: downloadsURL)
        } else {
            print("다운로드 폴더를 열 수 없습니다.")
        }
    }
}
