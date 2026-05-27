# 빌드 전 설정

## 1. 플랫폼 파일 생성 (최초 1회)

`smarband_app/` 디렉터리 안에 `android/`, `ios/` 폴더가 없으면 아래 명령으로 생성합니다:

```bash
cd smarband_app
flutter create --platforms android,ios .
```

## 2. Android 권한 (`android/app/src/main/AndroidManifest.xml`)

`<manifest>` 태그 바로 안에 추가:

```xml
<!-- Android 12+(API 31+): 스캔·연결 권한 -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 이하: BLE 스캔에 위치 권한 필요 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- BLE 기능 선언 (선택) -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

> **주의**: `BLUETOOTH_SCAN`에 `android:usesPermissionFlags="neverForLocation"` 플래그를
> 추가해야 위치 권한 없이도 Android 12+에서 스캔이 가능합니다.

## 3. iOS 권한 (`ios/Runner/Info.plist`)

`<dict>` 안에 추가:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>스마트밴드와 BLE 연결에 사용합니다</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>스마트밴드와 BLE 연결에 사용합니다</string>
```

## 4. 설치 및 실행

```bash
flutter pub get
flutter run
```
