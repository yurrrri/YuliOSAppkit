//
//  PhotoPermissionManager.swift
//  iOSAppkit
//
//  Created by 이유리 on 2/24/26.
//

/*
 iOS 14+
 
 1. info.plist에 다음 권한 추가
 <key>NSPhotoLibraryUsageDescription</key>
 <string>사진 라이브러리에 접근하기 위해 권한이 필요합니다.</string>
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>사진을 저장하기 위해 권한이 필요합니다.</string>
 */
import Photos
import UIKit

struct PhotoClient {
  
  init() {}
  
  /// 2. 현재 권한 상태 체크
  public func checkPermission() -> PHAuthorizationStatus {
    PHPhotoLibrary.authorizationStatus(for: .readWrite)
  }
  
  /// 3. 권한 요청 후 결과에 따라 처리
  /// - Parameters:
  ///   - granted: 권한 허용 시 실행할 클로저
  ///   - denied: 권한 거부 시 실행할 클로저 (설정 화면으로 이동 등)
  public func requestPermission(
    granted: @escaping () -> Void,
    denied: @escaping () -> Void
  ) {
    let status = checkPermission()
    switch status {
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
        DispatchQueue.main.async {
          switch newStatus {
          case .authorized, .limited:
            granted()
          default:
            denied()
          }
        }
      }
    case .authorized, .limited:
      granted()
    default:
      denied()
    }
  }
  
  public func requestPermission() async -> PHAuthorizationStatus {
      let status = checkPermission()
      guard status == .notDetermined else { return status }
      return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
  }
  
  /// 4. 권한 거부 시 설정 앱으로 이동하여 유도하기
  public func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else { return }
    UIApplication.shared.open(url)
  }
}
