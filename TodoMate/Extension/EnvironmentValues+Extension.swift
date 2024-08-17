//
//  EnvironmentValues+Extension.swift
//  TodoMate
//
//  Created by hs on 8/17/24.
//

import SwiftUI

extension EnvironmentValues {
    var calendarManager: CalendarManager {
        get { self[CalendarManagerKey.self] }
        set { self[CalendarManagerKey.self] = newValue }
    }
}

private struct CalendarManagerKey: EnvironmentKey {
    static let defaultValue = CalendarManager.shared
}
