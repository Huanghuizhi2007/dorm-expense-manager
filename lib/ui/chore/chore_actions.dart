import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/chore_calculator.dart';
import '../../data/models/chore_task.dart';
import '../../state/dorm_controller.dart';
import '../widgets/member_avatar.dart';

class _ChoreAdjustResult {
  const _ChoreAdjustResult({required this.date, required this.memberId});

  final DateTime date;
  final String memberId;
}

String memberNameById(DormController dorm, String memberId) {
  for (final member in dorm.members) {
    if (member.userId == memberId) return member.username;
  }
  return '成员';
}

String choreErrorMessage(Object error) {
  if (error is StateError) return error.message;
  return '操作失败，请检查网络后重试';
}

Future<void> completeChore(BuildContext context, ChoreTask task) async {
  final dorm = context.read<DormController>();
  final memberName = memberNameById(dorm, task.memberId);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('完成值日'),
      content: Text('确认 ${fullDate(task.taskDate)} 由 $memberName 完成了宿舍值日？'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('完成'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await dorm.completeChoreTask(task);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已完成，记录已同步')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(choreErrorMessage(error))),
      );
    }
  }
}

Future<void> showChoreAdjustSheet(
  BuildContext context, {
  DateTime? initialDate,
}) async {
  final dorm = context.read<DormController>();
  if (dorm.members.isEmpty) return;
  var selectedDate = dateOnly(initialDate ?? DateTime.now());
  var selectedMemberId = dorm.members.first.userId;

  final result = await showModalBottomSheet<_ChoreAdjustResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('调整单日值日', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '只修改选中当天，后续自动排班不会受影响。',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded),
                  title: Text(fullDate(selectedDate)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = dateOnly(picked));
                    }
                  },
                ),
                const SizedBox(height: 8),
                for (final member in dorm.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => setState(() => selectedMemberId = member.userId),
                    leading: MemberAvatar(
                      name: member.username,
                      imageUrl: member.avatarUrl,
                      size: 30,
                      seed: member.userId,
                    ),
                    title: Text(member.username),
                    trailing: Icon(
                      selectedMemberId == member.userId
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selectedMemberId == member.userId
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).hintColor,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _ChoreAdjustResult(
                        date: selectedDate,
                        memberId: selectedMemberId,
                      ),
                    ),
                    child: const Text('保存调整'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (result == null || !context.mounted) return;
  try {
    await dorm.adjustChoreTask(
      date: result.date,
      memberId: result.memberId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已调整为手动值日')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(choreErrorMessage(error))),
      );
    }
  }
}
