import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/posture_event.dart';

class SmartNeckService {
  static const _deviceName = 'SmartNeck';
  static final _serviceUuid = Guid('19b10000-e8f2-537e-4f6c-d104768a1214');
  static final _characteristicUuid = Guid('19b10001-e8f2-537e-4f6c-d104768a1214');

  final _statusController = StreamController<PostureStatus>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<PostureStatus> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  BluetoothDevice? _device;
  StreamSubscription? _scanSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _valueSub;
  bool _scanning = false;
  bool _reconnecting = false;

  // ── 1단계: 스캔 ──────────────────────────────────────────────────────────
  // withServices로 서비스 UUID 필터링 → 기기 이름만으론 iOS 스캔 누락 가능.
  // 이름 일치 확인 후 즉시 스캔 중단 → 연결 진행.
  // 10초 내 기기 미발견 시 3초 후 재시도.
  Future<void> startScan() async {
    if (_scanning) return;
    _scanning = true;

    await FlutterBluePlus.stopScan();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final result in results) {
        if (result.device.platformName == _deviceName) {
          await FlutterBluePlus.stopScan();
          await _connect(result.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(
      withServices: [_serviceUuid],
      timeout: const Duration(seconds: 10),
    );
    _scanning = false;

    if (_device == null) {
      await Future.delayed(const Duration(seconds: 3));
      startScan();
    }
  }

  // ── 2단계: 연결 및 서비스 탐색 ──────────────────────────────────────────
  // connect() → discoverServices() → 서비스 UUID → 특성 UUID → Notify 구독.
  // 연결 끊김 감지 시 _scheduleReconnect()로 재스캔 예약.
  Future<void> _connect(BluetoothDevice device) async {
    _device = device;

    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      final connected = state == BluetoothConnectionState.connected;
      _connectionController.add(connected);
      if (!connected) {
        _valueSub?.cancel();
        _device = null;
        _scheduleReconnect();
      }
    });

    try {
      await device.connect();

      // ── 3단계: UUID로 특성 탐색 → Notify 등록 ───────────────────────────
      // Arduino 광고 서비스(19B10000-…) 안의 특성(19B10001-…)을 찾아
      // setNotifyValue(true)로 구독 → 값 변화 시 _onValue() 자동 호출.
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid == _serviceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid == _characteristicUuid) {
              await char.setNotifyValue(true);
              _valueSub = char.onValueReceived.listen(_onValue);
            }
          }
        }
      }
    } catch (_) {
      _device = null;
      _scheduleReconnect();
    }
  }

  // _connectionSub와 catch가 동시에 트리거돼도 재스캔이 한 번만 실행되도록 보장
  void _scheduleReconnect() {
    if (_reconnecting) return;
    _reconnecting = true;
    Future.delayed(const Duration(seconds: 2), () {
      _reconnecting = false;
      startScan();
    });
  }

  // ── 4단계: 값 수신 ───────────────────────────────────────────────────────
  // Arduino BLE Notify 1바이트: 0 = 정상, 1 = 경고(≥60°), 2 = 위험(≥80°)
  void _onValue(List<int> value) {
    if (value.isEmpty) return;
    final status = switch (value[0]) {
      1 => PostureStatus.warning,
      2 => PostureStatus.danger,
      _ => PostureStatus.normal,
    };
    _statusController.add(status);
  }

  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _valueSub?.cancel();
    _statusController.close();
    _connectionController.close();
    _device?.disconnect();
  }
}
