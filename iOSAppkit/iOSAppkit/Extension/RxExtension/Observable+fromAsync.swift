//
//  Observable+fromAsync.swift
//  Utility
//
//  Created by 이유리 on 2/12/26.
//

import Foundation
import RxSwift

public extension Observable {
  static func fromAsync(_ asyncTask: @escaping () async throws -> Element) -> Observable<Element> {
    return Observable.create { observer in
      let task = Task {
        do {
          let result = try await asyncTask()
          observer.onNext(result)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
  
  static func fromAsync<Object: AnyObject>(
    with object: Object,
    _ asyncTask: @escaping (Object) async throws -> Element
  ) -> Observable<Element> {
    return Observable.create { observer in
      let task = Task { [weak object] in
        guard let object else {
          observer.onCompleted()
          return
        }
        
        do {
          let result = try await asyncTask(object)
          observer.onNext(result)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      
      return Disposables.create { task.cancel() }
    }
  }
}
