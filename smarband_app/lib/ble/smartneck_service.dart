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

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _scanning = false;

    // 기기를 못 찾으면 재시도
    if (_device == null) {
      await Future.delayed(const Duration(seconds: 3));
      startScan();
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    _device = device;

    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      final connected = state == BluetoothConnectionState.connected;
      _connectionController.add(connected);
      if (!connected) {
        _valueSub?.cancel();
        _device = null;
        Future.delayed(const Duration(seconds: 2), startScan);
      }
    });

    try {
      await device.connect();
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
      Future.delayed(const Duration(seconds: 2), startScan);
    }
  }

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
