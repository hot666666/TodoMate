import CoreFoundation
import Foundation

enum GRDBDatabaseRegion: String, CaseIterable, Sendable {
  case todo
  case memo
}

/// Bridges committed GRDB changes between processes that share the same database file.
///
/// `CFNotificationCenter` does not retain observers, and callbacks can arrive on arbitrary
/// threads. All mutable state is therefore protected by `lock`.
final class GRDBDatabaseChangeCenter: @unchecked Sendable {
  private typealias Continuation = AsyncStream<Void>.Continuation

  private let lock = NSLock()
  private let notificationNames: [GRDBDatabaseRegion: String]
  private var continuations: [GRDBDatabaseRegion: [UUID: Continuation]] = [:]

  init(baseNotificationName: String?) {
    notificationNames = if let baseNotificationName {
      Dictionary(
        uniqueKeysWithValues: GRDBDatabaseRegion.allCases.map {
          ($0, "\(baseNotificationName).\($0.rawValue).changed")
        },
      )
    } else {
      [:]
    }

    guard !notificationNames.isEmpty else { return }
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = Unmanaged.passUnretained(self).toOpaque()
    for name in notificationNames.values {
      CFNotificationCenterAddObserver(
        center,
        observer,
        grdbDatabaseChangeCallback,
        name as CFString,
        nil,
        .deliverImmediately,
      )
    }
  }

  deinit {
    if !notificationNames.isEmpty {
      CFNotificationCenterRemoveEveryObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        Unmanaged.passUnretained(self).toOpaque(),
      )
    }

    lock.lock()
    let activeContinuations = continuations.values.flatMap(\.values)
    continuations.removeAll()
    lock.unlock()
    activeContinuations.forEach { $0.finish() }
  }

  func changes(in region: GRDBDatabaseRegion) -> AsyncStream<Void> {
    let id = UUID()
    return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      lock.lock()
      continuations[region, default: [:]][id] = continuation
      lock.unlock()

      continuation.onTermination = { [weak self] _ in
        self?.removeContinuation(id: id, region: region)
      }
    }
  }

  /// Called after a transaction that modified `region` has committed.
  func notifyChange(in region: GRDBDatabaseRegion) {
    publish(region)

    guard let name = notificationNames[region] else { return }
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(name as CFString),
      nil,
      nil,
      true,
    )
  }

  fileprivate func receiveDarwinNotification(named name: String) {
    guard let region = notificationNames.first(where: { $0.value == name })?.key else { return }
    publish(region)
  }

  private func publish(_ region: GRDBDatabaseRegion) {
    lock.lock()
    let regionContinuations = Array(continuations[region, default: [:]].values)
    lock.unlock()
    regionContinuations.forEach { $0.yield() }
  }

  private func removeContinuation(id: UUID, region: GRDBDatabaseRegion) {
    lock.lock()
    continuations[region]?[id] = nil
    lock.unlock()
  }
}

private func grdbDatabaseChangeCallback(
  _: CFNotificationCenter?,
  observer: UnsafeMutableRawPointer?,
  name: CFNotificationName?,
  _: UnsafeRawPointer?,
  _: CFDictionary?,
) {
  guard let observer, let name else { return }
  let changeCenter = Unmanaged<GRDBDatabaseChangeCenter>
    .fromOpaque(observer)
    .takeUnretainedValue()
  changeCenter.receiveDarwinNotification(named: name.rawValue as String)
}
