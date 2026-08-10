import Foundation
import Testing
@testable import TodoMateDomain

@Suite("Project")
struct ProjectTests {
  @Test("Project name trims surrounding whitespace")
  func projectNameNormalization() throws {
    #expect(try ProjectName("  Study  ").value == "Study")
  }

  @Test("Project name rejects empty and oversized input")
  func projectNameValidation() {
    #expect(throws: ProjectName.ValidationError.empty) {
      try ProjectName(" \n ")
    }
    #expect(throws: ProjectName.ValidationError.tooLong(maximum: 80)) {
      try ProjectName(String(repeating: "a", count: 81))
    }
  }
}
