//
//  UIView+.swift
//  iOSAppkit
//
//  Created by 이유리 on 2/26/26.
//

import UIKit

extension UIView {
  func addSubviews(_ views: [UIView]) {
    views.forEach { self.addSubview($0) }
  }
}
