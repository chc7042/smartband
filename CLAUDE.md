# CLAUDE.md

이 파일은 이 저장소에서 작업하는 Claude Code(claude.ai/code)에게 안내를 제공합니다.

## 프로젝트 개요

**Smarband**는 가속도 센서로 목 자세를 감지하고 햅틱 피드백을 제공하는 2-MCU Arduino 스마트 넥밴드입니다. 두 개의 `.ino` 스케치는 각각 별도의 보드에서 실행되며, 디지털 핀 2번·3번을 통해 서로 통신합니다.

## 하드웨어 및 라이브러리

- **메인 보드** (`neck_posture_ble.ino`): Arduino Nano 33 IoT (LSM6DS3 + BLE 탑재 동급 보드)
  - 라이브러리: `Arduino_LSM6DS3`, `ArduinoBLE`
- **햅틱 보드** (`haptic_feedback.ino`): 5번 핀에 진동 모터가 연결된 Arduino

## 빌드 및 업로드

Arduino CLI 또는 Arduino IDE를 사용합니다. Arduino CLI 기준:

```bash
# 컴파일 (<board>를 예: arduino:mbed_nano:nano33iot 로 교체)
arduino-cli compile --fqbn <board> neck_posture_ble.ino

# 업로드 (<port>를 예: /dev/ttyACM0 으로 교체)
arduino-cli upload --fqbn <board> -p <port> neck_posture_ble.ino
```

`haptic_feedback.ino`도 동일한 방식으로 햅틱 보드에 업로드합니다.

시리얼 모니터(9600 baud)에서 메인 보드의 `Angle: <값>` 출력으로 디버깅할 수 있습니다.

## 아키텍처

### 보드 간 배선
메인 보드는 2번 핀(경고)과 3번 핀(위험)으로 디지털 출력을 내보냅니다. 이 핀들이 햅틱 보드의 입력 핀 2번·3번에 직접 연결됩니다.

### 자세 감지 로직 (`neck_posture_ble.ino`)
- LSM6DS3의 Y축 가속도를 읽어 각도 계산: `angle = abs(y) * 90`
- **경고** (≥60°): 2번 핀 200 ms HIGH (논블로킹); BLE 값 `1` 전송
- **위험** (≥80°): 3번 핀 200 ms HIGH (논블로킹); BLE 값 `2` 전송
- **정상** (<60°): BLE 값 `0` 전송
- 트리거 간 2초 쿨다운 (`lastTriggerTime` / `cooldown`)
- 핀 HIGH → LOW 전환은 `millis()` 기반 논블로킹으로 처리하여 `BLE.poll()` 차단 없음
- BLE 서비스 UUID `19B10000-…`, 특성 UUID `19B10001-…`, 기기 이름 `"SmartNeck"`; 값 `0` = 정상, `1` = 경고, `2` = 위험

### 햅틱 응답 로직 (`haptic_feedback.ino`)
- 상승 에지(rising edge)에서만 트리거되어 신호가 HIGH로 유지되는 동안 중복 실행 방지
- **경고** (≥60°): 진동 1회 × 300 ms ON
- **위험** (≥80°): 진동 2회 × 500 ms ON / 200 ms OFF
- 입력 핀(2, 3번)은 `INPUT_PULLDOWN` 사용; AVR 보드는 10kΩ 외부 풀다운 저항 필요
