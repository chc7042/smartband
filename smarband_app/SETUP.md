# 빌드 전 권한 설정

## Android (`android/app/src/main/AndroidManifest.xml`)

`<manifest>` 태그 안에 추가:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## iOS (`ios/Runner/Info.plist`)

`<dict>` 안에 추가:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>스마트밴드와 BLE 연결에 사용합니다</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>스마트밴드와 BLE 연결에 사용합니다</string>
```

## 설치 및 실행

```bash
flutter pub get
flutter run
```
