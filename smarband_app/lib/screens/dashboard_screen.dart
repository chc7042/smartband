import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/posture_event.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return Column(
              children: [
                _Header(isConnected: state.isConnected),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        _PostureCard(status: state.currentStatus),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          warningCount: state.todayWarningCount,
                          dangerCount: state.todayDangerCount,
                        ),
                        const SizedBox(height: 12),
                        _LastEventTile(event: state.lastEvent),
                        const SizedBox(height: 20),
                        _HistoryButton(onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: state,
                                child: const HistoryScreen(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── 헤더 ───────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.isConnected});
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Smarband',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              _BleBadge(isConnected: isConnected),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isConnected ? 'SmartNeck' : 'SmartNeck 검색 중...',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}

class _BleBadge extends StatelessWidget {
  const _BleBadge({required this.isConnected});
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF00A651) : const Color(0xFFD32F2F);
    final bg = isConnected ? const Color(0xFFE6F9F0) : const Color(0xFFFDECEA);
    final label = isConnected ? '연결됨' : '연결 안됨';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── 자세 카드 ──────────────────────────────────────────
class _PostureCard extends StatelessWidget {
  const _PostureCard({required this.status});
  final PostureStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: config.color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        children: [
          const Text('현재 자세', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          const SizedBox(height: 16),
          Text(config.icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(config.label,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: config.color)),
          const SizedBox(height: 6),
          Text(config.sub, style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('BLE 값: ${config.bleValue}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: config.color)),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(PostureStatus status) {
    switch (status) {
      case PostureStatus.normal:
        return _StatusConfig(
          icon: '🟢', label: '정상', sub: '올바른 자세를 유지하고 있어요', bleValue: '0',
          color: const Color(0xFF00A651), bgColor: const Color(0xFFE6F9F0),
        );
      case PostureStatus.warning:
        return _StatusConfig(
          icon: '🟡', label: '경고', sub: '목이 60° 이상 기울어졌어요', bleValue: '1',
          color: const Color(0xFFF5A623), bgColor: const Color(0xFFFFF8E7),
        );
      case PostureStatus.danger:
        return _StatusConfig(
          icon: '🔴', label: '위험', sub: '목이 80° 이상 기울어졌어요', bleValue: '2',
          color: const Color(0xFFD32F2F), bgColor: const Color(0xFFFDECEA),
        );
    }
  }
}

class _StatusConfig {
  final String icon, label, sub, bleValue;
  final Color color, bgColor;
  const _StatusConfig({
    required this.icon, required this.label, required this.sub,
    required this.bleValue, required this.color, required this.bgColor,
  });
}

// ── 요약 카드 행 ───────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.warningCount, required this.dangerCount});
  final int warningCount, dangerCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: '오늘 경고', count: warningCount,
            color: const Color(0xFFF5A623))),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(label: '오늘 위험', count: dangerCount,
            color: const Color(0xFFD32F2F))),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: color)),
          const Text('회', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
        ],
      ),
    );
  }
}

// ── 마지막 이벤트 ──────────────────────────────────────
class _LastEventTile extends StatelessWidget {
  const _LastEventTile({required this.event});
  final PostureEvent? event;

  @override
  Widget build(BuildContext context) {
    final todayEvent = event != null && _isToday(event!.timestamp) ? event : null;
    final timeText = todayEvent == null
        ? '-'
        : '${todayEvent.timestamp.hour.toString().padLeft(2, '0')}:${todayEvent.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('마지막 이벤트', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
              const SizedBox(height: 4),
              Text(timeText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
            ],
          ),
          if (todayEvent != null)
            _EventTag(status: todayEvent.status),
        ],
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

class _EventTag extends StatelessWidget {
  const _EventTag({required this.status});
  final PostureStatus status;

  @override
  Widget build(BuildContext context) {
    final isWarning = status == PostureStatus.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF8E7) : const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isWarning ? '경고' : '위험',
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isWarning ? const Color(0xFFF5A623) : const Color(0xFFD32F2F),
        ),
      ),
    );
  }
}

// ── 히스토리 버튼 ──────────────────────────────────────
class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('히스토리 보기 →',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }
}
