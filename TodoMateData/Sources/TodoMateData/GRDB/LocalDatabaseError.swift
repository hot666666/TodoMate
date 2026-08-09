import Foundation

public enum LocalDatabaseError: Error, Equatable {
  case appGroupContainerUnavailable(String)
  case databaseCoordinationFailed(URL)
  case invalidTodoStatus(String)
  case malformedLegacyRecord(String)
}
