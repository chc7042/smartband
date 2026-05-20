import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/posture_event.dart';
import 'ble/smartneck_service.dart';

class AppState extends ChangeNotifier {
  final _ble = SmartNeckService();

  PostureStatus currentStatus = PostureStatus.normal;
  bool isConnected = false;
  final List<PostureEvent> events = [];

  StreamSubscription? _statusSub;
  StreamSubscription? _connSub;

  AppState() {
    _statusSub = _ble.statusStream.listen(_onStatus);
    _connSub = _ble.connectionStream.listen(_onConnection);
    _ble.startScan();
  }

  void _onStatus(PostureStatus status) {
    currentStatus = status;
    if (status != PostureStatus.normal) {
      events.add(PostureEvent(timestamp: DateTime.now(), status: status));
    }
    notifyListeners();
  }

  void _onConnection(bool connected) {
    isConnected = connected;
    if (!connected) currentStatus = PostureStatus.normal;
    notifyListeners();
  }

  List<PostureEvent> get todayEvents {
    final now = DateTime.now();
    return events
        .where((e) =>
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day)
        .toList();
  }

  int get todayWarningCount =>
      todayEvents.where((e) => e.status == PostureStatus.warning).length;

  int get todayDangerCount =>
      todayEvents.where((e) => e.status == PostureStatus.danger).length;

  PostureEvent? get lastEvent => events.isEmpty ? null : events.last;

  @override
  void dispose() {
    _statusSub?.cancel();
    _connSub?.cancel();
    _ble.dispose();
    super.dispose();
  }
}
