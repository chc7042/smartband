#include <Arduino_LSM6DS3.h>
#include <ArduinoBLE.h>

BLEService smartNeckService("19B10000-E8F2-537E-4F6C-D104768A1214");
BLEUnsignedCharCharacteristic dataCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify);

const int toWarning = 2;
const int toDanger = 3;

unsigned long lastTriggerTime = 0;
const long cooldown = 2000;

int pulsePin = -1;
unsigned long pulseEndTime = 0;

void setup() {
  Serial.begin(9600);

  if (!IMU.begin()) {
    while (1);
  }

  if (!BLE.begin()) {
    while (1);
  }

  BLE.setLocalName("SmartNeck");
  BLE.setAdvertisedService(smartNeckService);
  smartNeckService.addCharacteristic(dataCharacteristic);
  BLE.addService(smartNeckService);
  dataCharacteristic.writeValue(0);
  BLE.advertise();

  pinMode(toWarning, OUTPUT);
  pinMode(toDanger, OUTPUT);
  digitalWrite(toWarning, LOW);
  digitalWrite(toDanger, LOW);
}

void startPulse(int pin) {
  pulsePin = pin;
  digitalWrite(pin, HIGH);
  pulseEndTime = millis() + 200;
}

void loop() {
  BLE.poll();

  if (pulsePin >= 0 && millis() >= pulseEndTime) {
    digitalWrite(pulsePin, LOW);
    pulsePin = -1;
  }

  float x, y, z;
  if (IMU.accelerationAvailable()) {
    IMU.readAcceleration(x, y, z);
    float angle = asin(constrain(abs(y), 0.0, 1.0)) * 180.0 / PI;

    // 디버깅 시에만 활성화 — 9600 baud 출력이 BLE poll 주기를 지연시킴
    // Serial.print("Angle: ");
    // Serial.println(angle);

    if (angle >= 80) {
      if (millis() - lastTriggerTime > cooldown) {
        startPulse(toDanger);
        dataCharacteristic.writeValue(2);
        lastTriggerTime = millis();
      }
    } else if (angle >= 60) {
      if (millis() - lastTriggerTime > cooldown) {
        startPulse(toWarning);
        dataCharacteristic.writeValue(1);
        lastTriggerTime = millis();
      }
    } else {
      if (dataCharacteristic.value() != 0)
        dataCharacteristic.writeValue(0);
    }
  }
}
