//
//  Debouncer.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Combine
import Foundation

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        /// 해당 입력 이전 입력의 delay가 아직 다 지나지 않았다면, 취소 후 새로 추가
        /// 이때 delay 후 action이 수행되는 구조
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}
