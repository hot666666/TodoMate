//
//  UTType+Extension.swift
//  TodoMate
//
//  Created by hs on 8/26/24.
//

import UniformTypeIdentifiers

extension UTType {
    static var todo: UTType {
        UTType(exportedAs: "io.hotcs6.TodoMate")
    }
}
