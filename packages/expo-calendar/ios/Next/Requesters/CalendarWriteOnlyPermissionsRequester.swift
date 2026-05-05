import ExpoModulesCore
import EventKit
internal import React

public class CalendarWriteOnlyPermissionsRequester: NSObject, EXPermissionsRequester {
  private let eventStore: EKEventStore

  init(eventStore: EKEventStore) {
    self.eventStore = eventStore
  }

  static public func permissionType() -> String {
    return "calendarWriteOnly"
  }

  public func getPermissions() -> [AnyHashable: Any] {
    guard Bundle.main.object(forInfoDictionaryKey: CalendarPlistKeys.calendarWriteOnly) != nil
      || Bundle.main.object(forInfoDictionaryKey: CalendarPlistKeys.calendarFullAccess) != nil else {
      return ["status": EXPermissionStatusDenied.rawValue, "canAskAgain": false]
    }

    var status: EXPermissionStatus
    switch EKEventStore.authorizationStatus(for: .event) {
    case .restricted, .denied:
      status = EXPermissionStatusDenied
    case .notDetermined:
      status = EXPermissionStatusUndetermined
    case .writeOnly, .fullAccess:
      status = EXPermissionStatusGranted
    @unknown default:
      status = EXPermissionStatusUndetermined
    }

    return ["status": status.rawValue, "canAskAgain": status == EXPermissionStatusUndetermined]
  }

  public func requestPermissions(resolver resolve: @escaping EXPromiseResolveBlock, rejecter reject: @escaping EXPromiseRejectBlock) {
    guard Bundle.main.object(forInfoDictionaryKey: CalendarPlistKeys.calendarWriteOnly) != nil else {
      reject("E_MISSING_PLIST", "Cannot request write-only calendar permissions because \(CalendarPlistKeys.calendarWriteOnly) is missing from your Info.plist. Add it via the expo-calendar config plugin or manually.", nil)
      return
    }
    if #available(iOS 17.0, *) {
      eventStore.requestWriteOnlyAccessToEvents { [weak self] _, error in
        guard let self else {
          return
        }
        if let error {
          reject("E_CALENDAR_ERROR_UNKNOWN", error.localizedDescription, error)
        } else {
          resolve(self.getPermissions())
        }
      }
    } else {
      eventStore.requestAccess(to: .event) { [weak self] _, error in
        guard let self else {
          return
        }
        if let error {
          reject("E_CALENDAR_ERROR_UNKNOWN", error.localizedDescription, error)
        } else {
          resolve(self.getPermissions())
        }
      }
    }
  }
}
