import TodoMateDomain

enum LocalAuthorID {
  static let canonical = User.local.id
  static let knownPlaceholderAliases = ["", EntityConstant.User.stubId]

  static func canonicalizing(_ ownerID: String) -> String {
    knownPlaceholderAliases.contains(ownerID) ? canonical : ownerID
  }
}
