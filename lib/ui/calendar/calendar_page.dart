import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics.dart';
import '../../core/app_constants.dart';
import '../../core/chore_calculator.dart';
import '../../data/models/expense.dart';
import '../../state/dorm_controller.dart';
import '../chore/chore_actions.dart';
import '../chore/chore_home_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';
import '../widgets/chore_task_tile.dart';

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
    final choreDays = <int>{
      for (final task in dorm.choreTasks)
        if (sameMonth(task.taskDate, _month)) task.taskDate.day,
    };
    final selectedExpenses = _selectedDate == null
        ? <Expense>[]
        : expensesOnDay(dorm.expenses, _selectedDate!);
    final selectedChore = _selectedDate == null
        ? null
        : taskOnDate(dorm.choreTasks, _selectedDate!);
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
        const SizedBox(height: 10),
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChoreHomePage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE9A23B).withOpacity(0.45),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9A23B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cleaning_services_outlined,
                      color: Color(0xFFE9A23B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          dorm.choreRule == null ? '宿舍值日安排' : '今日值日',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _choreEntrySubtitle(dorm, now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
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
            final hasChore = choreDays.contains(day);
            return _DayCell(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              hasExpense: hasExpense,
              hasChore: hasChore,
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
          if (selectedChore != null) ...[
            Text('值日任务', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            ChoreTaskTile(
              task: selectedChore,
              memberName: memberNameById(dorm, selectedChore.memberId),
              showDate: false,
              onComplete: selectedChore.isDone
                  ? null
                  : () => completeChore(context, selectedChore),
              onAdjust: selectedChore.isDone
                  ? null
                  : () => showChoreAdjustSheet(
                      context,
                      initialDate: selectedChore.taskDate,
                    ),
            ),
            const SizedBox(height: 20),
          ],
          if (selectedExpenses.isEmpty && selectedChore == null)
            const EmptyState(
              icon: Icons.event_available_rounded,
              title: '当天没有安排',
              description: '没有消费记录，也没有值日任务。',
            )
          else if (selectedExpenses.isNotEmpty) ...[
            Text('消费记录', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final expense in selectedExpenses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpenseTile(expense: expense),
              ),
          ],
        ] else
          Text(
            '点击日期查看当天消费',
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }

  String _choreEntrySubtitle(DormController dorm, DateTime now) {
    if (dorm.choreRule == null) {
      return '还没有值日规则，点击设置排班';
    }
    final todayTask = taskOnDate(dorm.choreTasks, now);
    if (todayTask == null) return '今天没有排班，点击查看本周安排';
    final name = memberNameById(dorm, todayTask.memberId);
    return todayTask.isDone ? '$name 已完成今天值日' : '今天轮到 $name 值日';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasExpense,
    required this.hasChore,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasExpense;
  final bool hasChore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAny = hasExpense || hasChore;
    final backgroundColor = isSelected
        ? theme.colorScheme.primary
        : hasAny
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (hasExpense)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasChore)
                  Container(
                    width: 5,
                    height: 5,
                    margin: EdgeInsets.only(
                      left: hasExpense ? 3 : 0,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9A23B),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
