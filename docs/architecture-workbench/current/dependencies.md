---
schemaVersion: 1
documentId: current.dependencies
modelLayer: dependencies
verifiedGitCommit: 81f29883bbda166d7387a0090abe6e34ff69bc32
status: current
---

# Compile-time Dependencies

# Nodes

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| module.domain | depends-on | module.common | observed | high | TodoMateDomain/Package.swift#dependencies: [; TodoMateDomain/Package.swift#"Common", |
| module.application | depends-on | module.domain | observed | high | TodoMateDomain/Package.swift#dependencies: ["TodoMateDomain"] |
| module.data | depends-on | module.domain | observed | high | TodoMateData/Package.swift#"TodoMateDomain", |
| module.data | depends-on | module.application | observed | high | TodoMateData/Package.swift#.product(name: "TodoMateApplication" |
| module.data | depends-on | module.common | observed | high | TodoMateData/Package.swift#"Common", |
| module.presentation | depends-on | module.domain | observed | high | TodoMatePresentation/Package.swift#.product(name: "TodoMateDomain" |
| module.presentation | depends-on | module.application | observed | high | TodoMatePresentation/Package.swift#.product(name: "TodoMateApplication" |
| module.presentation | depends-on | module.uitest-contracts | observed | high | TodoMatePresentation/Package.swift#"TodoMateUITestContracts", |
| target.app | depends-on | module.common | observed | high | TodoMate.xcodeproj/project.pbxproj#456ECB682F17B7E100DB8E88 /* Common */ |
| target.app | depends-on | module.domain | observed | high | TodoMate.xcodeproj/project.pbxproj#456ECAA02F17B44400DB8E88 /* TodoMateDomain */ |
| target.app | depends-on | module.application | observed | high | TodoMate.xcodeproj/project.pbxproj#A12800072F30000700000001 /* TodoMateApplication */ |
| target.app | depends-on | module.data | observed | high | TodoMate.xcodeproj/project.pbxproj#456ECA9D2F17B40100DB8E88 /* TodoMateData */ |
| target.app | depends-on | module.presentation | observed | high | TodoMate.xcodeproj/project.pbxproj#A12800022F30000200000001 /* TodoMatePresentation */ |
| target.ui-tests | depends-on | module.uitest-contracts | observed | high | TodoMate.xcodeproj/project.pbxproj#A12800052F30000500000001 /* TodoMateUITestContracts */ |
| executable.grdb-readonly-probe | depends-on | module.data | observed | high | TodoMateData/Package.swift#dependencies: ["TodoMateData", "TodoMateDomain"] |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |

# Traces

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
