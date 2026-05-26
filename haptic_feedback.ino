const int inWarning = 2;
const int inDanger = 3;
const int motorPin = 5;

bool lastWarningState = LOW;
bool lastDangerState = LOW;

void setup() {
  pinMode(inWarning, INPUT);
  pinMode(inDanger, INPUT);
  pinMode(motorPin, OUTPUT);
}

void loop() {
  bool currentWarning = digitalRead(inWarning);
  bool currentDanger = digitalRead(inDanger);

  // 위험: 진동 2회 × 500ms ON / 200ms OFF
  if (currentDanger == HIGH && lastDangerState == LOW) {
    vibrate(2, 500, 200);
  }
  // 경고: 진동 1회 × 300ms ON
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
