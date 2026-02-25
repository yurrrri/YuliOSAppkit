//
//  Observable+Pulse.swift
//
//

import Foundation
import RxSwift
import ReactorKit

public extension Observable {
  func pulse<Result>(_ transformToPulse: @escaping (Element) throws -> Pulse<Result>) -> Observable<Result> {
    return self.map(transformToPulse).distinctUntilChanged(\.valueUpdatedCount).map(\.value)
  }
}
