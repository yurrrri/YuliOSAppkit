//
//  KeychainStorage.swift
//  iOSAppkit
//
//  Created by 이유리 on 3/4/26.
//

import Foundation
import Security

public enum KeychainStorageError: Swift.Error, CustomStringConvertible, LocalizedError {
  case keychain(status: OSStatus, operation: Operation, service: String, key: String)
  case unexpectedItemType(expected: String, actual: String?)

  public enum Operation: String {
    case setDataUpdate = "SecItemUpdate"
    case setDataAdd = "SecItemAdd"
    case setDataRetryUpdate = "SecItemUpdate(retry)"
    case getData = "SecItemCopyMatching"
    case delete = "SecItemDelete"
  }

  public var errorDescription: String? { description }

  public var description: String {
    switch self {
    case let .keychain(status, operation, service, key):
      let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown"
      return "KeychainStorageError: \(operation.rawValue) 실패 (status=\(status), message=\(message)) service=\(service) key=\(key)"
    case let .unexpectedItemType(expected, actual):
      return "KeychainStorageError: 반환 타입 불일치 (expected=\(expected), actual=\(actual ?? "nil"))"
    }
  }
}

public final class KeychainStorage {
  public enum Key: String {
     case accessToken
     case refreshToken
  }

  private static let service: String = {
    let bid = Bundle.main.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let bid, !bid.isEmpty { return bid }
    return "KeychainStorage.default.service"
  }()
  
  private let lock = NSLock()
  
  public init() {}
}

// MARK: - Public

public extension KeychainStorage {
  func set(_ value: String, for key: Key) {
    do {
      try self.withThrowingSet(value, for: key)
    } catch {
      guard let error = error as? KeychainStorageError else {
        print("\(Self.self).\(#function) unknown error: \(error)")
        return
      }
      print("\(Self.self).\(#function) error: \(error)")
    }
  }
  
  func get(for key: Key) -> String? {
    do {
      return try self.withThrowingGet(for: key)
    } catch {
      guard let error = error as? KeychainStorageError else {
        print("\(Self.self).\(#function) unknown error: \(error)")
        return nil
      }
      print("\(Self.self).\(#function) error: \(error)")
      return nil
    }
  }
  
  func delete(_ key: Key) {
    do {
      return try self.withThrowingDelete(key)
    } catch {
      guard let error = error as? KeychainStorageError else {
        print("\(Self.self).\(#function) unknown error: \(error)")
        return
      }
      print("\(Self.self).\(#function) error: \(error)")
      return
    }
  }
  
  func withThrowingSet(_ value: String, for key: Key) throws {
    let data = Data(value.utf8)
    try setData(data, for: key.rawValue)
  }

  func withThrowingGet(for key: Key) throws -> String? {
    guard let data = try getData(for: key.rawValue) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  func withThrowingDelete(_ key: Key) throws {
    lock.lock()
    defer { lock.unlock() }
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: key.rawValue
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainStorageError.keychain(
        status: status,
        operation: .delete,
        service: Self.service,
        key: key.rawValue
      )
    }
  }
}

// MARK: - Low-level

extension KeychainStorage {
  private func setData(_ data: Data, for account: String) throws {
    lock.lock()
    defer { lock.unlock() }
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: account
    ]

    let attributes: [String: Any] = [
      kSecValueData as String: data
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    if updateStatus == errSecItemNotFound {
      var addQuery = query
      addQuery[kSecValueData as String] = data

      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      if addStatus == errSecSuccess { return }

      // 다른 프로세스(Siri, Widget 등)가 동시에 add할 수 있으므로 duplicate 방어
      if addStatus == errSecDuplicateItem {
        let retryStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard retryStatus == errSecSuccess else {
          throw KeychainStorageError.keychain(
            status: retryStatus,
            operation: .setDataRetryUpdate,
            service: Self.service,
            key: account
          )
        }
        return
      }

      throw KeychainStorageError.keychain(
        status: addStatus,
        operation: .setDataAdd,
        service: Self.service,
        key: account
      )
    }

    guard updateStatus == errSecSuccess else {
      throw KeychainStorageError.keychain(
        status: updateStatus,
        operation: .setDataUpdate,
        service: Self.service,
        key: account
      )
    }
  }

  private func getData(for account: String) throws -> Data? {
    lock.lock()
    defer { lock.unlock() }
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound { return nil }

    guard status == errSecSuccess else {
      throw KeychainStorageError.keychain(
        status: status,
        operation: .getData,
        service: Self.service,
        key: account
      )
    }

    guard let data = item as? Data else {
      let actual = item.map { String(describing: type(of: $0)) }
      throw KeychainStorageError.unexpectedItemType(expected: "Data", actual: actual)
    }

    return data
  }
}
