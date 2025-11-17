// ==================================================
// Statistics Dashboard Screen for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2025-01-17
// Purpose: Display comprehensive walking statistics
// ==================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/statistics_model.dart';
import '../../services/statistics_service.dart';

class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  State<StatisticsDashboardScreen> createState() =>
      _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState
    extends State<StatisticsDashboardScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  
  PeriodStatistics? _todayStats;
  PeriodStatistics? _weekStats;
  PeriodStatistics? _monthStats;
  List<MonthlyStatistics> _monthlyStats = [];
  List<AreaStatistics> _areaStats = [];
  
  bool _isLoading = true;
  String? _error;
  
  // 期間選択
  String _selectedPeriod = 'month'; // 'today', 'week', 'month'

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// 統計データを読み込み
  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 並列でデータ取得
      final results = await Future.wait([
        _statisticsService.getTodayStatistics(),
        _statisticsService.getThisWeekStatistics(),
        _statisticsService.getThisMonthStatistics(),
        _statisticsService.getMonthlyStatistics(
          startMonth: DateTime.now().subtract(const Duration(days: 180)),
          endMonth: DateTime.now(),
        ),
        _statisticsService.getAreaStatistics(
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          endDate: DateTime.now(),
        ),
      ]);

      if (mounted) {
        setState(() {
          _todayStats = results[0] as PeriodStatistics;
          _weekStats = results[1] as PeriodStatistics;
          _monthStats = results[2] as PeriodStatistics;
          _monthlyStats = results[3] as List<MonthlyStatistics>;
          _areaStats = results[4] as List<AreaStatistics>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラーが発生しました', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildCurrentPeriodStats(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildMonthlyChart(),
          const SizedBox(height: 24),
          _buildAreaRanking(),
        ],
      ),
    );
  }

  /// 期間選択タブ
  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _PeriodTab(
            label: '今日',
            isSelected: _selectedPeriod == 'today',
            onTap: () => setState(() => _selectedPeriod = 'today'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodTab(
            label: '今週',
            isSelected: _selectedPeriod == 'week',
            onTap: () => setState(() => _selectedPeriod = 'week'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodTab(
            label: '今月',
            isSelected: _selectedPeriod == 'month',
            onTap: () => setState(() => _selectedPeriod = 'month'),
          ),
        ),
      ],
    );
  }

  /// 選択期間の統計
  Widget _buildCurrentPeriodStats() {
    PeriodStatistics? stats;
    switch (_selectedPeriod) {
      case 'today':
        stats = _todayStats;
        break;
      case 'week':
        stats = _weekStats;
        break;
      case 'month':
        stats = _monthStats;
        break;
    }

    if (stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('データがありません')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.directions_walk,
                  label: '散歩回数',
                  value: '${stats.totalRoutes}回',
                ),
                _StatItem(
                  icon: Icons.straighten,
                  label: '総距離',
                  value: stats.formattedTotalDistance,
                ),
                _StatItem(
                  icon: Icons.timer,
                  label: '総時間',
                  value: stats.formattedTotalDuration,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.show_chart,
                  label: '平均距離',
                  value: stats.formattedAvgDistance,
                ),
                _StatItem(
                  icon: Icons.access_time,
                  label: '平均時間',
                  value: stats.formattedAvgDuration,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// クイック統計（全期間）
  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイック統計',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.today, color: Colors.blue, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${_todayStats?.totalRoutes ?? 0}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('今日の散歩'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.green, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${_weekStats?.totalRoutes ?? 0}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('今週の散歩'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 月別チャート（簡易版）
  Widget _buildMonthlyChart() {
    if (_monthlyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '月別推移',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _monthlyStats.take(6).map((stat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          stat.monthLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: stat.totalRoutes > 0
                              ? (stat.totalRoutes / 30).clamp(0.0, 1.0)
                              : 0,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${stat.totalRoutes}回'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// エリア別ランキング
  Widget _buildAreaRanking() {
    if (_areaStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'よく行くエリア（過去90日）',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _areaStats.take(5).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final area = _areaStats[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(area.areaName),
                subtitle: Text(
                  '${area.totalRoutes}回 • ${area.formattedTotalDistance}',
                ),
                trailing: Text(
                  area.lastVisitLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 期間選択タブ
class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 統計アイテム
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
