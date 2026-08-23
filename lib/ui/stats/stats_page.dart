import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/settlement_calculator.dart';
import '../../data/models/dorm_member.dart';
import '../../data/models/settlement_entry.dart';
import '../../data/supabase_service.dart';
import '../../state/dorm_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/member_avatar.dart';
import 'settlement_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late DateTime _month;
  bool _syncing = false;
  String? _syncError;
  List<SettlementEntry> _serverEntries = <SettlementEntry>[];

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSettlements();
    });
  }

  Future<void> _syncSettlements() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    try {
      final entries = await context.read<DormController>().syncSettlements(_month);
      if (mounted) setState(() => _serverEntries = entries);
    } catch (_) {
      if (mounted) {
        setState(() {
          _syncError = '云端结算未生成，下方仍按本地数据实时计算。';
        });
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
      _serverEntries = <SettlementEntry>[];
    });
    _syncSettlements();
  }

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1, 1);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month + 1, 1))) return;
    setState(() {
      _month = next;
      _serverEntries = <SettlementEntry>[];
    });
    _syncSettlements();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final result = SettlementCalculator.calculate(
      expenses: dorm.expenses,
      members: dorm.members,
      month: _month,
    );
    final currentUserId = SupabaseService.client.auth.currentUser?.id ?? '';
    final myLine = result.lines.where((line) => line.userId == currentUserId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('统计', style: theme.textTheme.headlineMedium)),
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: '上一个月',
            ),
            Text(monthLabel(_month), style: theme.textTheme.titleMedium),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: '下一个月',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (dorm.expenses.isEmpty)
          const EmptyState(
            icon: Icons.query_stats_rounded,
            title: '本月还没有支出',
            description: '先去记一笔支出，统计和结算会自动生成。',
          )
        else ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: <Widget>[
              _MetricCard(
                label: '本月总支出',
                value: money(result.total),
                icon: Icons.payments_outlined,
              ),
              _MetricCard(
                label: '人均承担',
                value: money(result.average),
                icon: Icons.account_balance_wallet_outlined,
              ),
              _MetricCard(
                label: '支出笔数',
                value: '${dorm.expenses.where((e) => sameMonth(e.createdAt, _month)).length} 笔',
                icon: Icons.receipt_long_outlined,
              ),
              _MetricCard(
                label: '宿舍成员',
                value: '${dorm.members.length} 人',
                icon: Icons.group_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (myLine.isNotEmpty)
            _MySettlementCard(
              line: myLine.first,
              total: result.total,
            ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(child: Text('成员消费排行', style: theme.textTheme.titleLarge)),
              if (_syncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in _ranking(result.lines))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RankingTile(line: line, maxPaid: _maxPaid(result.lines)),
            ),
          if (_syncError != null) ...[
            Text(
              _syncError!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _syncing ? null : _syncSettlements,
            icon: const Icon(Icons.sync_rounded),
            label: Text(_syncing ? '正在同步…' : '生成并同步本月结算'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettlementPage(initialMonth: _month),
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('查看完整结算单'),
          ),
        ],
      ],
    );
  }

  List<BalanceLine> _ranking(List<BalanceLine> lines) {
    final sorted = <BalanceLine>[...lines];
    sorted.sort((a, b) => b.paidCents.compareTo(a.paidCents));
    return sorted;
  }

  int _maxPaid(List<BalanceLine> lines) {
    if (lines.isEmpty) return 0;
    var max = 0;
    for (final line in lines) {
      if (line.paidCents > max) max = line.paidCents;
    }
    return max;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MySettlementCard extends StatelessWidget {
  const _MySettlementCard({required this.line, required this.total});

  final BalanceLine line;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = line.balanceCents >= 0
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final status = line.balanceCents >= 0
        ? '应收 ${money(line.balance.abs())}'
        : '还需支付 ${money(line.balance.abs())}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('我的本月', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniValue(label: '已支付', value: money(line.paid)),
              ),
              Expanded(
                child: _MiniValue(label: '应承担', value: money(line.share)),
              ),
              Expanded(
                child: _MiniValue(label: '结算', value: status, color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  const _MiniValue({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color ?? theme.textTheme.titleMedium?.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.line, required this.maxPaid});

  final BalanceLine line;
  final int maxPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = maxPaid == 0 ? 0.0 : line.paidCents / maxPaid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: <Widget>[
          MemberAvatar(
            name: line.username,
            size: 32,
            seed: line.userId,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        line.username,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      money(line.paid),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
