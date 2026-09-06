import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../data/models/dorm_member.dart';
import '../../state/dorm_controller.dart';
import '../widgets/member_avatar.dart';
import 'chore_actions.dart';

class ChoreSettingsPage extends StatefulWidget {
  const ChoreSettingsPage({super.key});

  @override
  State<ChoreSettingsPage> createState() => _ChoreSettingsPageState();
}

class _ChoreSettingsPageState extends State<ChoreSettingsPage> {
  static const List<int> _presetDays = <int>[1, 2, 3, 7];

  bool _initialized = false;
  List<DormMember> _availableMembers = <DormMember>[];
  List<String> _order = <String>[];
  int _intervalDays = 1;
  bool _customMode = false;
  DateTime _startDate = DateTime.now();
  final TextEditingController _customController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final dorm = context.read<DormController>();
    _availableMembers = List<DormMember>.from(dorm.members);
    final rule = dorm.choreRule;
    _startDate = rule?.startDate ?? DateTime.now();
    _intervalDays = rule?.intervalDays ?? 1;
    _customMode = !_presetDays.contains(_intervalDays);
    _customController.text = _customMode ? '$_intervalDays' : '';

    final memberIds = <String>{
      for (final member in _availableMembers) member.userId,
    };
    _order = <String>[
      for (final id in rule?.memberOrder ?? <String>[])
        if (memberIds.contains(id)) id,
      for (final member in _availableMembers)
        if (!(rule?.memberOrder ?? <String>[]).contains(member.userId))
          member.userId,
    ];
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (_order.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要一名成员参与值日')),
      );
      return;
    }
    var interval = _intervalDays;
    if (_customMode) {
      interval = int.tryParse(_customController.text.trim()) ?? 0;
    }
    if (interval < 1 || interval > 366) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('间隔天数需要是 1-366 之间的整数')),
      );
      return;
    }

    final dorm = context.read<DormController>();
    try {
      await dorm.saveChoreRule(
        memberOrder: _order,
        intervalDays: interval,
        startDate: _startDate,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(choreErrorMessage(error))),
        );
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('值日规则已保存，未来安排已重新生成')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final rule = dorm.choreRule;
    final subtitle = rule == null
        ? '新规则会从开始日期自动生成未来至少 6 个月安排。'
        : '修改规则只会重建未来未完成安排，已完成的记录不会被覆盖。';

    return Scaffold(
      appBar: AppBar(title: const Text('值日规则设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          Text('成员顺序', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('长按右侧拖动图标调整顺序', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: _order.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('当前宿舍还没有成员，请先邀请舍友加入。'),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _order.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final moved = _order.removeAt(oldIndex);
                        _order.insert(newIndex, moved);
                      });
                    },
                    itemBuilder: (context, index) {
                      final member = _memberById(_order[index]);
                      return ListTile(
                        key: ValueKey<String>(_order[index]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: MemberAvatar(
                          name: member?.username ?? '成员',
                          imageUrl: member?.avatarUrl,
                          size: 34,
                          seed: _order[index],
                        ),
                        title: Text(member?.username ?? '成员'),
                        subtitle: Text('第 ${index + 1} 位'),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_indicator_rounded),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          Text('值日间隔', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('每天'),
                selected: !_customMode && _intervalDays == 1,
                onSelected: (_) {
                  setState(() {
                    _customMode = false;
                    _intervalDays = 1;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('每 2 天'),
                selected: !_customMode && _intervalDays == 2,
                onSelected: (_) {
                  setState(() {
                    _customMode = false;
                    _intervalDays = 2;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('每 3 天'),
                selected: !_customMode && _intervalDays == 3,
                onSelected: (_) {
                  setState(() {
                    _customMode = false;
                    _intervalDays = 3;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('每周'),
                selected: !_customMode && _intervalDays == 7,
                onSelected: (_) {
                  setState(() {
                    _customMode = false;
                    _intervalDays = 7;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('自定义'),
                selected: _customMode,
                onSelected: (_) {
                  setState(() {
                    _customMode = true;
                    _customController.text =
                        _customMode && _customController.text.isEmpty
                            ? '$_intervalDays'
                            : _customController.text;
                  });
                },
              ),
            ],
          ),
          if (_customMode) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '自定义间隔天数',
                hintText: '例如 5',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('开始日期', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            tileColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.dividerColor),
            ),
            leading: const Icon(Icons.event_rounded),
            title: Text(fullDate(_startDate)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: dorm.isLoading ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(dorm.isLoading ? '保存中...' : '保存规则并生成安排'),
          ),
        ],
      ),
    );
  }

  DormMember? _memberById(String userId) {
    for (final member in _availableMembers) {
      if (member.userId == userId) return member;
    }
    return null;
  }
}
