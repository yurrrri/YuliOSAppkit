//
//  Array+.swift
//  iOSAppkit
//
//  Created by 이유리 on 2/26/26.
//

import Foundation

public extension Array {
  subscript(safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}
