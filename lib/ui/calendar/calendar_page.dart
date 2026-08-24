import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics.dart';
import '../../core/app_constants.dart';
import '../../data/models/expense.dart';
import '../../state/dorm_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1, 1);
      _selectedDate = null;
    });
  }

  void _backToToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final markedDays = expenseDaysInMonth(dorm.expenses, _month);
    final selectedExpenses = _selectedDate == null
        ? <Expense>[]
        : expensesOnDay(dorm.expenses, _selectedDate!);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingEmpty = DateTime(_month.year, _month.month, 1).weekday - 1;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('日历', style: theme.textTheme.headlineMedium)),
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: '上个月',
            ),
            Text(monthLabel(_month), style: theme.textTheme.titleMedium),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: '下个月',
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _backToToday,
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('今天'),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            for (final label in const <String>['一', '二', '三', '四', '五', '六', '日'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: leadingEmpty + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) return const SizedBox.shrink();
            final day = index - leadingEmpty + 1;
            final date = DateTime(_month.year, _month.month, day);
            final isToday =
                date.year == now.year && date.month == now.month && date.day == now.day;
            final isSelected = _selectedDate != null &&
                sameDay(_selectedDate!, date);
            final hasExpense = markedDays.contains(day);
            return _DayCell(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              hasExpense: hasExpense,
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
            );
          },
        ),
        const SizedBox(height: 20),
        if (_selectedDate != null) ...[
          Text(
            fullDate(_selectedDate!),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (selectedExpenses.isEmpty)
            const EmptyState(
              icon: Icons.event_available_rounded,
              title: '当天没有消费记录',
              description: '点击“记一笔”可以补充当天的支出。',
            )
          else
            for (final expense in selectedExpenses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpenseTile(expense: expense),
              ),
        ] else
          Text(
            '点击日期查看当天消费',
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasExpense,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasExpense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isSelected
        ? theme.colorScheme.primary
        : hasExpense
            ? theme.colorScheme.primary.withOpacity(0.08)
            : Colors.transparent;
    final textColor = isSelected
        ? Colors.white
        : isToday
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$day',
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasExpense
                    ? (isSelected ? Colors.white : theme.colorScheme.primary)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
