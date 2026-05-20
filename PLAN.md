# Smarband 개발 계획

## 현재 상태

Arduino 2-MCU 구성으로 목 자세 감지 및 햅틱 피드백까지 동작 중.
BLE 전송도 구현되어 있으나 Flutter 앱이 없음.

### 하드웨어 구성
- **메인 보드** (`neck_posture_ble.ino`): IMU로 각도 계산 → BLE 전송 + 디지털 핀 출력
- **햅틱 보드** (`haptic_feedback.ino`): 핀 신호 수신 → 진동 모터 제어

---

## 버그 수정

### [완료] 진동 횟수 불일치 수정 (`haptic_feedback.ino`)

| 상태 | 기획 | 현재 코드 |
|------|------|----------|
| 경고 (≥60°) | 진동 1번 | 진동 2번 ← 잘못됨 |
| 위험 (≥80°) | 진동 2번 | 진동 1번 ← 잘못됨 |

**수정 내용**: `vibrate()` 호출 인자 교체
- 경고: `vibrate(2, 300, 200)` → `vibrate(1, 300, 0)`
- 위험: `vibrate(1, 1000, 0)` → `vibrate(2, 500, 200)`

---

## Flutter 앱 개발

### BLE 연결 정보
- 기기 이름: `SmartNeck`
- 서비스 UUID: `19B10000-E8F2-537E-4F6C-D104768A1214`
- 특성 UUID: `19B10001-E8F2-537E-4F6C-D104768A1214` (Read + Notify)
- 값: `0` = 정상, `1` = 경고, `2` = 위험

### 요구사항
1. **경고/위험 알림**: BLE notify 수신 시 로컬 푸시 알림
2. **횟수 그래프**: 경고/위험 발생 횟수를 시간대별로 시각화

### 단계별 구현 계획

#### 1단계: 프로젝트 세팅
- [ ] `flutter create smarband_app`
- [ ] 패키지 추가: `flutter_blue_plus`, `flutter_local_notifications`, `fl_chart`
- [ ] iOS/Android 권한 설정 (BLE, 알림)

#### 2단계: BLE 서비스 (`lib/ble/smartneck_service.dart`)
- [ ] 기기 스캔 및 `SmartNeck` 자동 연결
- [ ] 특성 notify 구독 → Stream으로 값 노출
- [ ] 연결 끊김 시 자동 재연결

#### 3단계: 알림 서비스 (`lib/services/notification_service.dart`)
- [ ] `flutter_local_notifications` 초기화
- [ ] 값 `1` 수신 → "목 자세 경고" 알림
- [ ] 값 `2` 수신 → "목 자세 위험" 알림

#### 4단계: 대시보드 화면 (`lib/screens/dashboard_screen.dart`)
- [ ] BLE 연결 상태 표시 (연결 중 / 연결됨 / 끊김)
- [ ] 현재 자세 상태 실시간 표시 (정상/경고/위험)
- [ ] 오늘 누적 경고/위험 횟수 요약
- [ ] 시각화 화면으로 이동 버튼

#### 5단계: 시각화 화면 (`lib/screens/stats_screen.dart`)
- [ ] 이벤트 로그 누적 (타임스탬프 + 상태값)
- [ ] `fl_chart` 막대 그래프: 시간대별 경고/위험 횟수
- [ ] 경고(노랑) / 위험(빨강) 색상 구분
- [ ] 당일 / 주간 뷰 전환

### 앱 디렉토리 구조
```
smarband_app/
└── lib/
    ├── main.dart
    ├── ble/
    │   └── smartneck_service.dart
    ├── services/
    │   └── notification_service.dart
    ├── screens/
    │   ├── dashboard_screen.dart
    │   └── stats_screen.dart
    └── models/
        └── posture_event.dart       # 타임스탬프 + 상태값
```
