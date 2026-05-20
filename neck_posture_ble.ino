#include <Arduino_LSM6DS3.h>
#include <ArduinoBLE.h> // 블루투스 라이브러리

BLEService smartNeckService("19B10000-E8F2-537E-4F6C-D104768A1214");
BLEUnsignedCharCharacteristic dataCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);

const int toWarning = 2; 
const int toDanger = 3;  

unsigned long lastTriggerTime = 0; 
const long cooldown = 2000;        

void setup() {
  Serial.begin(9600);

  if (!IMU.begin()) {
    while (1); // IMU 에러 발생 시 대기
  }

  // 블루투스 스타트!
  if (!BLE.begin()) {
    while (1); // 블루투스 에러 발생 시 대기
  }

  // 아이폰이 알아볼 수 있게 이름과 주소 등록
  BLE.setLocalName("SmartNeck"); 
  BLE.setAdvertisedService(smartNeckService);
  smartNeckService.addCharacteristic(dataCharacteristic);
  BLE.addService(smartNeckService);
  
  // 데이터 초기값 0 세팅
  dataCharacteristic.writeValue(0);

  // 전파 방송 시작 (여기서 전파가 뿜어져 나옵니다!)
  BLE.advertise();

  pinMode(toWarning, OUTPUT);
  pinMode(toDanger, OUTPUT);
  digitalWrite(toWarning, LOW);
  digitalWrite(toDanger, LOW);
}

void loop() {
  // 아이폰 연결 대기 코드를 제거하여, 스캔 단계에서도 신호가 끊기지 않게 합니다.
  BLE.poll(); 

  float x, y, z;
  if (IMU.accelerationAvailable()) {
    IMU.readAcceleration(x, y, z);
    
    // Y축 기준으로 각도 계산 (0~90도)
    float angle = abs(y) * 90.0; 

    // 디버깅용 시리얼 출력
    Serial.print("Angle: ");
    Serial.println(angle); 

    if (millis() - lastTriggerTime > cooldown) {
      if (angle >= 80) { 
        sendPulse(toDanger);
        dataCharacteristic.writeValue(2); // 블루투스로 숫자 '2' 전송
        lastTriggerTime = millis();
      } 
      else if (angle >= 60) { 
        sendPulse(toWarning);
        dataCharacteristic.writeValue(1); // 블루투스로 숫자 '1' 전송
        lastTriggerTime = millis();
      }
    }
  }
  delay(100); 
}

void sendPulse(int pin) {
  digitalWrite(pin, HIGH);
  delay(200); 
  digitalWrite(pin, LOW);
}