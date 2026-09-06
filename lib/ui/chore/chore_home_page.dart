import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/chore_calculator.dart';
import '../../data/models/chore_task.dart';
import '../../state/dorm_controller.dart';
import '../widgets/chore_task_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/member_avatar.dart';
import 'chore_actions.dart';
import 'chore_settings_page.dart';

class ChoreHomePage extends StatelessWidget {
  const ChoreHomePage({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChoreSettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final rule = dorm.choreRule;
    final tasks = dorm.choreTasks;
    final today = dateOnly(DateTime.now());
    final todayTask = taskOnDate(tasks, today);
    final weekStart = addCalendarDays(today, 1 - today.weekday);
    final weekEnd = addCalendarDays(weekStart, 6);
    final weekTasks = tasksBetween(
      tasks,
      start: weekStart,
      end: weekEnd,
    );
    final upcoming = tasks
        .where((task) => !task.taskDate.isBefore(today))
        .take(14)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('值日安排')),
      body: RefreshIndicator(
        onRefresh: () => dorm.refreshChores(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: <Widget>[
            if (rule == null) ...[
              const SizedBox(height: 60),
              EmptyState(
                icon: Icons.cleaning_services_outlined,
                title: '还没有值日规则',
                description: '设置成员顺序和值日间隔后，系统会自动生成未来半年安排。',
                action: FilledButton.icon(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('设置值日规则'),
                ),
              ),
            ] else ...[
              _TodayDutyCard(
                task: todayTask,
                memberName: todayTask == null
                    ? ''
                    : memberNameById(dorm, todayTask.memberId),
                ruleInterval: rule.intervalDays,
                onAdjust: () => showChoreAdjustSheet(context, initialDate: today),
                onComplete: todayTask == null
                    ? null
                    : () => completeChore(context, todayTask),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('本周安排', style: theme.textTheme.titleLarge),
                  ),
                  TextButton.icon(
                    onPressed: () => _openSettings(context),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('修改规则'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (weekTasks.isEmpty)
                _RuleCard(
                  child: Text(
                    '本周没有值日任务，点击“修改规则”查看设置。',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                for (final task in weekTasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ChoreTaskTile(
                      task: task,
                      memberName: memberNameById(dorm, task.memberId),
                      showDate: true,
                      onComplete: task.isDone
                          ? null
                          : () => completeChore(context, task),
                      onAdjust: task.isDone
                          ? null
                          : () => showChoreAdjustSheet(
                              context,
                              initialDate: task.taskDate,
                            ),
                    ),
                  ),
              const SizedBox(height: 12),
              _RuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('当前规则', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '值日顺序：${rule.memberOrder.map((id) => memberNameById(dorm, id)).join(' → ')}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '间隔：每 ${rule.intervalDays} 天 · 开始：${fullDate(rule.startDate)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('近期安排', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: '暂无未来任务',
                  description: '自动生成功能会按规则持续补充后续安排。',
                )
              else
                for (final task in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ChoreTaskTile(
                      task: task,
                      memberName: memberNameById(dorm, task.memberId),
                      showDate: true,
                      onComplete: task.isDone
                          ? null
                          : () => completeChore(context, task),
                      onAdjust: task.isDone
                          ? null
                          : () => showChoreAdjustSheet(
                              context,
                              initialDate: task.taskDate,
                            ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayDutyCard extends StatelessWidget {
  const _TodayDutyCard({
    required this.task,
    required this.memberName,
    required this.ruleInterval,
    this.onComplete,
    this.onAdjust,
  });

  final ChoreTask? task;
  final String memberName;
  final int ruleInterval;
  final VoidCallback? onComplete;
  final VoidCallback? onAdjust;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFE9A23B);
    final now = DateTime.now();
    final subtitle = task == null
        ? '今天没有排班，下一次任务会按每 $ruleInterval 天自动出现'
        : task!.isDone
            ? '今天值日已完成'
            : '今天待完成';

    return Material(
      color: const Color(0xFF1B3A36),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '今日值日',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (task == null)
              const Text(
                '🧹 今天休息',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              )
            else ...[
              Row(
                children: <Widget>[
                  MemberAvatar(
                    name: memberName,
                    imageUrl: null,
                    size: 34,
                    seed: task!.memberId,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '🧹 $memberName${task!.isDone ? '（已完成）' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              '${fullDate(now)} · $subtitle',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (task != null && !task!.isDone) ...[
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onAdjust,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.16),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: const Text('调整今天'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onComplete,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('完成值日'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}
