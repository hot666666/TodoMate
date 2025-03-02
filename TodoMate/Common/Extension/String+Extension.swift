//
//  String+Extension.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Foundation

extension String {
    func truncated(to length: Int = 17) -> String {
        if self.count > length {
            let index = self.index(self.startIndex, offsetBy: length)
            return String(self[..<index]) + "..."
        } else {
            return self
        }
    }
}
