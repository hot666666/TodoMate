//
//  PreviewTrait+Extension.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI
import SwiftData

// TODO: - MacOS 15+
struct SampleData: PreviewModifier {
    /// Preview에서 사용할 ModelContainer를 정의
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TodoItemEntity.self, configurations: config)
        
        /// @Model의 SampleData 생성
        TodoItemEntity.makeSampleTodoItems(in: container)
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

/// #Preview에서 traits 인자로 사용하기 위해 확장
extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self = .modifier(SampleData())
}
