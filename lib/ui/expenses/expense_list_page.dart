import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../data/models/expense.dart';
import '../../state/dorm_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';
import 'expense_edit_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  late DateTime _month;
  String _query = '';
  String _category = '全部';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openEdit(Expense? expense) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseEditPage(expense: expense),
      ),
    );
  }

  Future<void> _confirmDelete(DormController dorm, Expense expense) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，请检查网络后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final query = _query.trim().toLowerCase();

    var filtered = dorm.expenses
        .where((expense) => sameMonth(expense.createdAt, _month))
        .toList();
    if (_category != '全部') {
      filtered = filtered
          .where((expense) => expense.category == _category)
          .toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (expense) =>
                expense.title.toLowerCase().contains(query) ||
                (expense.payerName ?? '').toLowerCase().contains(query),
          )
          .toList();
    }

    final totalCents = filtered.fold<int>(
      0,
      (sum, expense) => sum + (expense.amount * 100).round(),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('账单', style: theme.textTheme.headlineMedium)),
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
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: '搜索支出名称或付款人',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (final category in <String>['全部', ...expenseCategories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    label: Text(category),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Text(
              '${filtered.length} 笔',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '合计 ${money(totalCents / 100)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: '没有匹配的支出',
            description: '换个关键词或月份试试，也可以点击右下角新增一笔。',
          )
        else
          for (final expense in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpenseTile(
                expense: expense,
                onTap: () => _openEdit(expense),
                onEdit: () => _openEdit(expense),
                onDelete: () => _confirmDelete(dorm, expense),
              ),
            ),
      ],
    );
  }
}
