//
//  Util.swift
//  TodoMate
//
//  Created by hs on 8/29/24.
//

import AppKit

enum Util { }
extension Util {
    // TodoMate VERSION.zip 형식에서 버전을 추출하는 함수
    static func extractVersion(from fileName: String) -> String? {
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
    
    // at위치에 있는 .zip파일을 to로 압축해제하는 함수
    static func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", sourceURL.path, destinationURL.path]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "UnzipErrorDomain", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to unzip file"])
        }
    }
    
    static func openFolder(at path: URL) {
        NSWorkspace.shared.open(path)
    }
}
