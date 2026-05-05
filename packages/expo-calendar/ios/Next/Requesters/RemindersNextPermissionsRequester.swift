import ExpoModulesCore
import EventKit
internal import React

public class RemindersNextPermissionRequester: NSObject, EXPermissionsRequester {
  private let eventStore: EKEventStore

  init(eventStore: EKEventStore) {
    self.eventStore = eventStore
  }

  static public func permissionType() -> String {
    return "reminders"
  }

  public func getPermissions() -> [AnyHashable: Any] {
    var status: EXPermissionStatus
    switch EKEventStore.authorizationStatus(for: .reminder) {
    case .restricted, .denied, .writeOnly:
      status = EXPermissionStatusDenied
    case .notDetermined:
      status = EXPermissionStatusUndetermined
    case .fullAccess:
      status = EXPermissionStatusGranted
    @unknown default:
      status = EXPermissionStatusUndetermined
    }

    return ["status": status.rawValue, "canAskAgain": status == EXPermissionStatusUndetermined]
  }

  public func requestPermissions(resolver resolve: @escaping EXPromiseResolveBlock, rejecter reject: @escaping EXPromiseRejectBlock) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToReminders { [weak self] _, error in
        guard let self else {
          return
        }
        if let error {
          reject("E_REMINDERS_ERROR_UNKNOWN", error.localizedDescription, error)
        } else {
          resolve(self.getPermissions())
        }
      }
    } else {
      eventStore.requestAccess(to: .reminder) { [weak self] _, error in
        guard let self else {
          return
        }
        if let error {
          reject("E_REMINDERS_ERROR_UNKNOWN", error.localizedDescription, error)
        } else {
          resolve(self.getPermissions())
        }
      }
    }
  }
}
