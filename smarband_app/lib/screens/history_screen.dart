import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/posture_event.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _tabIndex = 0; // 0=오늘, 1=이번 주
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final filtered = _tabIndex == 0
                ? _filterDay(state.events, _selectedDate)
                : _filterWeek(state.events, _selectedDate);

            final warningCount = filtered.where((e) => e.status == PostureStatus.warning).length;
            final dangerCount = filtered.where((e) => e.status == PostureStatus.danger).length;

            return Column(
              children: [
                _Header(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TabBar(
                          selected: _tabIndex,
                          onChanged: (i) => setState(() => _tabIndex = i),
                        ),
                        const SizedBox(height: 14),
                        _DateNav(
                          tabIndex: _tabIndex,
                          date: _selectedDate,
                          onPrev: () => setState(() {
                            _selectedDate = _tabIndex == 0
                                ? _selectedDate.subtract(const Duration(days: 1))
                                : _selectedDate.subtract(const Duration(days: 7));
                          }),
                          onNext: () {
                            final next = _tabIndex == 0
                                ? _selectedDate.add(const Duration(days: 1))
                                : _selectedDate.add(const Duration(days: 7));
                            if (!next.isAfter(DateTime.now())) {
                              setState(() => _selectedDate = next);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        _SummaryRow(warningCount: warningCount, dangerCount: dangerCount),
                        const SizedBox(height: 14),
                        _ChartCard(
                          events: filtered,
                          isDaily: _tabIndex == 0,
                        ),
                        const SizedBox(height: 16),
                        const Text('이벤트 로그',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
                        const SizedBox(height: 8),
                        _EventLog(events: filtered.reversed.toList()),
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

  List<PostureEvent> _filterDay(List<PostureEvent> all, DateTime date) => all
      .where((e) =>
          e.timestamp.year == date.year &&
          e.timestamp.month == date.month &&
          e.timestamp.day == date.day)
      .toList();

  List<PostureEvent> _filterWeek(List<PostureEvent> all, DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return all.where((e) =>
        e.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
        e.timestamp.isBefore(end)).toList();
  }
}

// ── 헤더 ───────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: onBack,
          ),
          const Text('히스토리',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── 탭 ─────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Tab(label: '오늘', active: selected == 0, onTap: () => onChanged(0)),
          _Tab(label: '이번 주', active: selected == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 날짜 네비게이션 ────────────────────────────────────
class _DateNav extends StatelessWidget {
  const _DateNav({
    required this.tabIndex,
    required this.date,
    required this.onPrev,
    required this.onNext,
  });
  final int tabIndex;
  final DateTime date;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final label = tabIndex == 0 ? _dayLabel(date) : _weekLabel(date);
    final isToday = tabIndex == 0 && _isSameDay(date, DateTime.now());
    final isThisWeek = tabIndex == 1 && _isSameWeek(date, DateTime.now());
    final canNext = !isToday && !isThisWeek;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPrev,
            child: const Icon(Icons.chevron_left, color: Color(0xFFAAAAAA)),
          ),
          Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          GestureDetector(
            onTap: canNext ? onNext : null,
            child: Icon(Icons.chevron_right,
                color: canNext ? const Color(0xFFAAAAAA) : const Color(0xFFDDDDDD)),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    if (_isSameDay(d, DateTime.now())) {
      return '${d.year}년 ${d.month}월 ${d.day}일 (오늘)';
    }
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  String _weekLabel(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${start.month}.${start.day.toString().padLeft(2,'0')} – ${end.month}.${end.day.toString().padLeft(2,'0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameWeek(DateTime a, DateTime b) {
    final startA = a.subtract(Duration(days: a.weekday - 1));
    final startB = b.subtract(Duration(days: b.weekday - 1));
    return _isSameDay(startA, startB);
  }
}

// ── 요약 카드 ──────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.warningCount, required this.dangerCount});
  final int warningCount, dangerCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Card(label: '경고', count: warningCount, color: const Color(0xFFF5A623))),
        const SizedBox(width: 10),
        Expanded(child: _Card(label: '위험', count: dangerCount, color: const Color(0xFFD32F2F))),
        const SizedBox(width: 10),
        Expanded(child: _Card(label: '합계', count: warningCount + dangerCount, color: const Color(0xFF555555))),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
          const Text('회', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
        ],
      ),
    );
  }
}

// ── 차트 ───────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.events, required this.isDaily});
  final List<PostureEvent> events;
  final bool isDaily;

  @override
  Widget build(BuildContext context) {
    final groups = isDaily ? _buildDailyGroups() : _buildWeeklyGroups();
    final maxY = groups.fold<double>(0, (m, g) =>
        m > (g.barRods.fold<double>(0, (s, r) => s + r.toY)) ? m : (g.barRods.fold<double>(0, (s, r) => s + r.toY)));
    final yMax = (maxY < 4 ? 4 : maxY + 1).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDaily ? '시간대별 발생 횟수' : '요일별 발생 횟수',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(const Color(0xFFF5A623), '경고'),
              const SizedBox(width: 14),
              _legend(const Color(0xFFD32F2F), '위험'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: groups.isEmpty
                ? const Center(
                    child: Text('이벤트 없음', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: yMax,
                      barGroups: groups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: const Color(0xFFF0F0F0), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 9, color: Color(0xFFBBBBBB)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final label = isDaily
                                  ? '${value.toInt()}'
                                  : _weekdayLabel(value.toInt());
                              return Text(label,
                                  style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA)));
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
    );
  }

  List<BarChartGroupData> _buildDailyGroups() {
    final Map<int, Map<PostureStatus, int>> grouped = {};
    for (final e in events) {
      final h = e.timestamp.hour;
      grouped.putIfAbsent(h, () => {});
      grouped[h]![e.status] = (grouped[h]![e.status] ?? 0) + 1;
    }
    return grouped.entries.map((entry) {
      final w = (entry.value[PostureStatus.warning] ?? 0).toDouble();
      final d = (entry.value[PostureStatus.danger] ?? 0).toDouble();
      return BarChartGroupData(
        x: entry.key,
        barsSpace: 2,
        barRods: [
          if (w > 0) BarChartRodData(toY: w, color: const Color(0xFFF5A623), width: 8, borderRadius: BorderRadius.circular(3)),
          if (d > 0) BarChartRodData(toY: d, color: const Color(0xFFD32F2F), width: 8, borderRadius: BorderRadius.circular(3)),
        ],
      );
    }).toList()..sort((a, b) => a.x.compareTo(b.x));
  }

  List<BarChartGroupData> _buildWeeklyGroups() {
    final Map<int, Map<PostureStatus, int>> grouped = {};
    for (int i = 1; i <= 7; i++) {
      grouped[i] = {};
    }
    for (final e in events) {
      final day = e.timestamp.weekday;
      grouped[day]![e.status] = (grouped[day]![e.status] ?? 0) + 1;
    }
    return grouped.entries.map((entry) {
      final w = (entry.value[PostureStatus.warning] ?? 0).toDouble();
      final d = (entry.value[PostureStatus.danger] ?? 0).toDouble();
      return BarChartGroupData(
        x: entry.key,
        barsSpace: 2,
        barRods: [
          BarChartRodData(toY: w, color: const Color(0xFFF5A623), width: 8, borderRadius: BorderRadius.circular(3)),
          BarChartRodData(toY: d, color: const Color(0xFFD32F2F), width: 8, borderRadius: BorderRadius.circular(3)),
        ],
      );
    }).toList()..sort((a, b) => a.x.compareTo(b.x));
  }

  String _weekdayLabel(int weekday) {
    const labels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    return labels[weekday] ?? '';
  }
}

// ── 이벤트 로그 ────────────────────────────────────────
class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});
  final List<PostureEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: const Text('기록 없음', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
      );
    }
    return Column(
      children: events
          .take(20)
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LogItem(event: e),
              ))
          .toList(),
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({required this.event});
  final PostureEvent event;

  @override
  Widget build(BuildContext context) {
    final isWarning = event.status == PostureStatus.warning;
    final timeStr =
        '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}';
    final bleValue = isWarning ? '1' : '2';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeStr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 2),
              Text('BLE 값: $bleValue',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
            ],
          ),
          Container(
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
          ),
        ],
      ),
    );
  }
}
