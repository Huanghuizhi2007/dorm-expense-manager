import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../data/models/chore_task.dart';
import 'member_avatar.dart';

class ChoreTaskTile extends StatelessWidget {
  const ChoreTaskTile({
    super.key,
    required this.task,
    required this.memberName,
    this.showDate = false,
    this.onComplete,
    this.onAdjust,
  });

  final ChoreTask task;
  final String memberName;
  final bool showDate;
  final VoidCallback? onComplete;
  final VoidCallback? onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = const Color(0xFFE9A23B);
    final done = task.isDone;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: done ? accent.withOpacity(0.45) : theme.dividerColor,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(done ? 0.28 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                done ? Icons.cleaning_services_rounded : Icons.cleaning_services_outlined,
                color: done ? accent : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          showDate ? fullDate(task.taskDate) : '宿舍值日',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (task.isManual)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '手动调整',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: done
                              ? const Color(0xFF0E7C6B).withOpacity(0.12)
                              : theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          done ? '已完成' : '待完成',
                          style: TextStyle(
                            color: done
                                ? const Color(0xFF0E7C6B)
                                : theme.colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      MemberAvatar(
                        name: memberName,
                        size: 22,
                        seed: task.memberId,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        memberName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (done && task.completedAt != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '完成于 ${_timeText(task.completedAt!)}',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!done && onAdjust != null)
              IconButton(
                tooltip: '调整成员',
                onPressed: onAdjust,
                icon: const Icon(Icons.edit_calendar_outlined, size: 20),
              ),
            if (!done && onComplete != null)
              TextButton(
                onPressed: onComplete,
                child: const Text('完成值日'),
              ),
          ],
        ),
      ),
    );
  }

  String _timeText(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
