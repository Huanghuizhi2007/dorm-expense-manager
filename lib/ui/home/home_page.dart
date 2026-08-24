import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../data/models/dorm_member.dart';
import '../../data/models/expense.dart';
import '../../state/auth_controller.dart';
import '../../state/dorm_controller.dart';
import '../expenses/expense_edit_page.dart';
import 'dorm_detail_page.dart';
import '../stats/settlement_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';
import '../widgets/member_avatar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  void _openEdit(BuildContext context, {Expense? expense}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseEditPage(expense: expense),
      ),
    );
  }

  void _openDormitory(BuildContext context) {
    final dormitory = context.read<DormController>().currentDormitory;
    if (dormitory == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DormDetailPage(dormitory: dormitory),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DormController dorm,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这笔支出？'),
        content: Text('${expense.title} · ${money(expense.amount)}'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await dorm.deleteExpense(expense.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，请检查网络后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final dorm = context.watch<DormController>();
    final dormitory = dorm.currentDormitory;
    final profile = auth.profile;

    final month = DateTime.now();
    final monthExpenses = dorm.expenses
        .where((expense) => sameMonth(expense.createdAt, month))
        .toList();
    final totalCents = monthExpenses.fold<int>(
      0,
      (sum, expense) => sum + (expense.amount * 100).round(),
    );
    final allExpenses = dorm.expenses;
    final visibleExpenses = allExpenses.take(_visibleCount).toList();
    final hasMore = _visibleCount < allExpenses.length;

    return CustomScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${month.month}月账单', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      '你好，${profile?.username ?? '成员'}',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              MemberAvatar(
                name: profile?.username ?? '我',
                imageUrl: profile?.avatarUrl,
                size: 44,
                seed: profile?.id ?? '',
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (dormitory != null)
          SliverToBoxAdapter(
            child: _DormitorySummaryCard(
              dormitoryName: dormitory.name,
              inviteCode: dormitory.inviteCode,
              members: dorm.members,
              monthTotal: totalCents / 100,
              onTap: () => _openDormitory(context),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text('全部账目', style: theme.textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettlementPage(),
                    ),
                  );
                },
                child: const Text('查看结算'),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (allExpenses.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: '还没有支出记录',
              description: '点击右下角“记一笔”，记录宿舍的第一笔公共支出。',
            ),
          )
        else
          SliverList.builder(
            itemCount: visibleExpenses.length,
            itemBuilder: (context, index) {
              final expense = visibleExpenses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpenseTile(
                  expense: expense,
                  onTap: () => _openEdit(context, expense: expense),
                  onEdit: () => _openEdit(context, expense: expense),
                  onDelete: () => _confirmDelete(context, dorm, expense),
                ),
              );
            },
          ),
        if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _visibleCount += _pageSize;
                  });
                },
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('加载更多'),
              ),
            ),
          ),
      ],
    );
  }
}

class _DormitorySummaryCard extends StatelessWidget {
  const _DormitorySummaryCard({
    required this.dormitoryName,
    required this.inviteCode,
    required this.members,
    required this.monthTotal,
    required this.onTap,
  });

  final String dormitoryName;
  final String inviteCode;
  final List<DormMember> members;
  final double monthTotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B3A36)
        : colorScheme.primary;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.home_work_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dormitoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '邀请码 $inviteCode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '本月消费',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money(monthTotal),
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
                    '成员',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${members.length} 人',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 28,
              child: Row(
                children: <Widget>[
                  for (var index = 0; index < members.length && index < 8; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == members.length - 1 ? 0 : 6,
                      ),
                      child: MemberAvatar(
                        name: members[index].username,
                        imageUrl: members[index].avatarUrl,
                        size: 28,
                        seed: members[index].userId,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '数据实时同步',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}
