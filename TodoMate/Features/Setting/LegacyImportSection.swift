//
//  LegacyImportSection.swift
//  TodoMate
//
//  Created by agent on 1/23/26.
//

import SwiftUI
import TodoMateDomain

struct LegacyImportSection: View {
  let user: User
  let importLegacyDataUseCase: ImportLegacyDataUseCase

  @State private var importState: ImportState = .idle
  @State private var showImportConfirmation: Bool = false

  enum ImportState {
    case idle
    case importing(progress: Double)
    case completed
    case failed(Error)
  }

  var body: some View {
    if isValidTargetForImport(user: user) {
      VStack(alignment: .leading, spacing: 16) {
        Text("Legacy Data Import")
          .font(.headline)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 12) {
          Text("4.0.0 이전 버전의 데이터를 기기로 가져옵니다.")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          switch importState {
          case .idle, .failed:
            Button {
              showImportConfirmation = true
            } label: {
              Text("불러오기")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if case let .failed(error) = importState {
              Text("실패: \(error.localizedDescription)")
                .font(.caption)
                .foregroundStyle(.red)
            }

          case let .importing(progress):
            VStack(spacing: 8) {
              ProgressView(value: progress)
              Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

          case .completed:
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
              Text("완료되었습니다")
            }
          }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .confirmationDialog(
        "데이터 가져오기",
        isPresented: $showImportConfirmation,
        titleVisibility: .visible,
      ) {
        Button("가져오기") {
          Task {
            await importLegacyData()
          }
        }
        Button("취소", role: .cancel) {}
      } message: {
        Text("기존 데이터(Todo, Memo)를 현재 기기로 가져옵니다.\n이미 존재하는 데이터는 건너뜁니다.")
      }
    }
  }

  // MARK: - Actions

  private func importLegacyData() async {
    importState = .importing(progress: 0.0)

    do {
      for try await progress in importLegacyDataUseCase.execute(userId: user.id) {
        importState = .importing(progress: progress)
      }
      importState = .completed
    } catch {
      importState = .failed(error)
    }
  }

  // MARK: - Helpers

  // Target Date: 2025-08-24 00:00:00 UTC
  private var legacyImportCutoffDate: Date? {
    var components = DateComponents()
    components.year = 2025
    components.month = 8
    components.day = 24
    components.timeZone = TimeZone(identifier: "UTC")
    return Calendar(identifier: .gregorian).date(from: components)
  }

  private func isValidTargetForImport(user: User) -> Bool {
    guard let cutoffDate = legacyImportCutoffDate else { return false }
    return user.createdAt < cutoffDate
  }
}
