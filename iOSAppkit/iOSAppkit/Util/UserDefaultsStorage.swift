//
//  UserDefaultsStorage.swift
//  iOSAppkit
//
//  Created by 이유리 on 3/4/26.
//

import Foundation

@propertyWrapper
public struct UserDefaultsStorage<T> {
  private let key: String
  private let defaultValue: T
  
  public init(key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }
  
  public var wrappedValue: T {
    get {
      guard let value = UserDefaults.standard.object(forKey: key) else {
        return defaultValue
      }
      return (value as? T) ?? defaultValue
    }
    set {
      if let value = newValue as? OptionalProtocol, value.isNil() {
        UserDefaults.standard.removeObject(forKey: key)
      } else {
        UserDefaults.standard.set(newValue, forKey: key)
      }
    }
  }
}

private protocol OptionalProtocol {
  func isNil() -> Bool
}

extension Optional: OptionalProtocol {
  func isNil() -> Bool {
    return self == nil
  }
}
