//
//  View+.swift
//  iOSAppkit
//
//  Created by 이유리 on 3/4/26.
//

import Foundation
import SwiftUI

public enum ViewVisibility {
  case gone
  case visible
  case invisible
}

fileprivate struct ViewVisibilityModifier: ViewModifier {
  private let visibility: ViewVisibility
  
  init(visibility: ViewVisibility) {
    self.visibility = visibility
  }
  
  @ViewBuilder
  func body(content: Content) -> some View {
    if self.visibility == .visible {
      content
    } else if self.visibility == .invisible {
      content.hidden()
    } else {
      EmptyView()
    }
  }
}

public extension View {
  @ViewBuilder
  func visibility(_ visibility: ViewVisibility) -> some View {
    modifier(ViewVisibilityModifier(visibility: visibility))
  }
}
