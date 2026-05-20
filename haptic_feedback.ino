const int inWarning = 2; 
const int inDanger = 3;  
const int motorPin = 5;  

bool lastWarningState = LOW;
bool lastDangerState = LOW;

void setup() {
  // AVR 보드는 INPUT_PULLDOWN 미지원 — 2, 3번 핀에 10kΩ 외부 풀다운 저항 필요
  pinMode(inWarning, INPUT_PULLDOWN);
  pinMode(inDanger, INPUT_PULLDOWN);
  pinMode(motorPin, OUTPUT);
}

void loop() {
  bool currentWarning = digitalRead(inWarning);
  bool currentDanger = digitalRead(inDanger);

  // 위험: 진동 2번 (기획안 기준)
  if (currentDanger == HIGH && lastDangerState == LOW) {
    vibrate(2, 500, 200);
  }
  // 경고: 진동 1번
  else if (currentWarning == HIGH && lastWarningState == LOW) {
    vibrate(1, 300, 0);
  }

  lastDangerState = currentDanger;
  lastWarningState = currentWarning;
  delay(10);
}

void vibrate(int count, int onTime, int offTime) {
  for (int i = 0; i < count; i++) {
    digitalWrite(motorPin, HIGH);
    delay(onTime);
    digitalWrite(motorPin, LOW);
    if (count > 1 && i < count - 1) delay(offTime);
  }
}