import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../data/models/dorm_member.dart';
import '../../data/models/dormitory.dart';
import '../../state/auth_controller.dart';
import '../../state/dorm_controller.dart';
import '../widgets/member_avatar.dart';

class DormDetailPage extends StatefulWidget {
  const DormDetailPage({super.key, required this.dormitory});

  final Dormitory dormitory;

  @override
  State<DormDetailPage> createState() => _DormDetailPageState();
}

class _DormDetailPageState extends State<DormDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dorm = context.read<DormController>();
      if (dorm.currentDormitory?.id != widget.dormitory.id) {
        await dorm.selectDormitory(widget.dormitory);
      }
    });
  }

  Future<void> _copyInviteCode() async {
    await Clipboard.setData(ClipboardData(text: widget.dormitory.inviteCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邀请码已复制')),
      );
    }
  }

  Future<void> _confirmDeleteDormitory() async {
    final currentUserId = context.read<AuthController>().profile?.id;
    if (widget.dormitory.creatorId != currentUserId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除宿舍？'),
        content: Text(
          '将删除“${widget.dormitory.name}”以及它的全部账单、成员关系，此操作无法恢复。',
        ),
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
      await context.read<DormController>().deleteDormitory(widget.dormitory.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('宿舍已删除')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.contains('NOT_DORMITORY_CREATOR')
                  ? '只有宿舍创建者可以删除宿舍。'
                  : '删除失败，请确认已运行删除宿舍的数据库更新。',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final auth = context.watch<AuthController>();
    final canDelete = auth.profile?.id == widget.dormitory.creatorId;
    final members = dorm.currentDormitory?.id == widget.dormitory.id
        ? dorm.members
        : <DormMember>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('宿舍详情'),
        actions: <Widget>[
          IconButton(
            onPressed: () => dorm.refresh(),
            tooltip: '刷新',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.dormitory.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Text(
                        '邀请码',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.dormitory.inviteCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _copyInviteCode,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.14),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('复制'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '当前成员 ${members.length} 人',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('宿舍成员', style: theme.textTheme.titleLarge),
                ),
                if (dorm.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (members.isEmpty && !dorm.isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  '暂时没有成员数据，点击右上角刷新。',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (final member in members)
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
                          name: member.username,
                          imageUrl: member.avatarUrl,
                          size: 38,
                          seed: member.userId,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                member.username,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.role == 'creator' ? '创建者' : '成员',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          shortDate(member.joinedAt),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          if (canDelete)
            OutlinedButton.icon(
              onPressed: _confirmDeleteDormitory,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('删除宿舍'),
            ),
          ],
        ),
      ),
    );
  }
}
