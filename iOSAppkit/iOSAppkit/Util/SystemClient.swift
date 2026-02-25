//
//  OpenSettingsURLString.swift
//  iOSAppkit
//
//  Created by 이유리 on 2/25/26.
//

import UIKit

// 시스템 성 유틸
public enum SystemClient {
  
  /// 설정창 이동
  public static func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else { return }
    UIApplication.shared.open(url)
  }
}
