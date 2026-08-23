import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/settlement_calculator.dart';
import '../../state/dorm_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';
import '../widgets/member_avatar.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({super.key, this.initialMonth});

  final DateTime? initialMonth;

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth ?? DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1, 1);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month + 1, 1))) return;
    setState(() {
      _month = next;
    });
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
    final monthExpenses = dorm.expenses
        .where((expense) => sameMonth(expense.createdAt, _month))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('结算单'),
        actions: <Widget>[
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: '上一个月',
          ),
          Center(
            child: Text(
              monthLabel(_month),
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: '下一个月',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '本月总支出',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(result.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      const Text(
                        '人均',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(result.average),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('谁该给谁', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (result.transfers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  '本月已经两清，不需要互相转账。',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (final transfer in result.transfers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: <Widget>[
                        MemberAvatar(
                          name: transfer.fromName,
                          size: 30,
                          seed: transfer.fromUserId,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transfer.fromName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        MemberAvatar(
                          name: transfer.toName,
                          size: 30,
                          seed: transfer.toUserId,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transfer.toName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          money(transfer.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 14),
            Text('成员结算明细', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (result.lines.isEmpty)
              const EmptyState(
                icon: Icons.group_off_outlined,
                title: '还没有宿舍成员',
                description: '创建或加入宿舍后即可自动结算。',
              )
            else
              for (final line in result.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SettlementLineTile(line: line),
                ),
            const SizedBox(height: 14),
            Text('本月明细', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (monthExpenses.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: '本月没有支出',
                description: '记录支出后会自动出现在这里。',
              )
            else
              for (final expense in monthExpenses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExpenseTile(expense: expense),
                ),
          ],
        ),
      ),
    );
  }
}

class _SettlementLineTile extends StatelessWidget {
  const _SettlementLineTile({required this.line});

  final BalanceLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = line.balanceCents >= 0;
    final status = positive
        ? '应收 ${money(line.balance)}'
        : '还需支付 ${money(line.balance.abs())}';
    final statusColor = positive
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              MemberAvatar(
                name: line.username,
                size: 32,
                seed: line.userId,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(line.username, style: theme.textTheme.titleMedium),
              ),
              Text(
                status,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _SettlementValue(label: '已支付', value: money(line.paid)),
              ),
              Expanded(
                child: _SettlementValue(label: '应承担', value: money(line.share)),
              ),
              Expanded(
                child: _SettlementValue(label: '差额', value: money(line.balance)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementValue extends StatelessWidget {
  const _SettlementValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

