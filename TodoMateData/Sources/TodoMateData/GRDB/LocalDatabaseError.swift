import Foundation

public enum LocalDatabaseError: Error, Equatable {
  case invalidTodoStatus(String)
}
