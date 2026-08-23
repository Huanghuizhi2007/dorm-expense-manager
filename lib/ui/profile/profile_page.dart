import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/dormitory.dart';
import '../../data/supabase_service.dart';
import '../../state/auth_controller.dart';
import '../../state/dorm_controller.dart';
import '../../state/theme_controller.dart';
import '../home/create_dorm_page.dart';
import '../home/dorm_detail_page.dart';
import '../home/join_dorm_page.dart';
import '../widgets/member_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _editUsername(BuildContext context) async {
    final auth = context.read<AuthController>();
    final profile = auth.profile;
    if (profile == null) return;
    final controller = TextEditingController(text: profile.username);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改用户名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(labelText: '用户名'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == profile.username) return;
    final error = await auth.updateProfile(username: result);
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _editAvatarUrl(BuildContext context) async {
    final auth = context.read<AuthController>();
    final profile = auth.profile;
    if (profile == null) return;
    final controller = TextEditingController(text: profile.avatarUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('头像图片链接'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '图片 URL',
            hintText: '留空使用首字母头像',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final error = await auth.updateProfile(avatarUrl: result);
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _confirmDeleteDormitory(
    BuildContext context,
    Dormitory dormitory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除宿舍？'),
        content: Text(
          '将删除“${dormitory.name}”以及它的全部账单、成员关系，此操作无法恢复。',
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
      await context.read<DormController>().deleteDormitory(dormitory.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('宿舍已删除')),
        );
      }
    } catch (error) {
      if (context.mounted) {
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

  Future<void> _openDormitory(
    BuildContext context,
    Dormitory dormitory,
  ) async {
    await context.read<DormController>().selectDormitory(dormitory);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DormDetailPage(dormitory: dormitory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final dorm = context.watch<DormController>();
    final themeController = context.watch<ThemeController>();
    final profile = auth.profile;
    final email = SupabaseService.client.auth.currentUser?.email ?? '';
    final currentUserId = profile?.id ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: <Widget>[
        Text('我的', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
                    name: profile?.username ?? '我',
                    imageUrl: profile?.avatarUrl,
                    size: 52,
                    seed: profile?.id ?? '',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile?.username ?? '成员',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(email, style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editUsername(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('改用户名'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editAvatarUrl(context),
                      icon: const Icon(Icons.portrait_outlined, size: 18),
                      label: const Text('改头像'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('外观', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SwitchListTile(
            value: themeController.isDark,
            onChanged: (value) => themeController.setDark(value),
            title: const Text('深色模式'),
            subtitle: const Text('跟随你的使用习惯'),
            secondary: Icon(
              themeController.isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(child: Text('我的宿舍', style: theme.textTheme.titleLarge)),
            IconButton(
              tooltip: '创建宿舍',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateDormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add_home_work_outlined),
            ),
            IconButton(
              tooltip: '加入宿舍',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const JoinDormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.group_add_outlined),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (dorm.dormitories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              '还没有宿舍，点击右上角创建或加入。',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          for (final dormitory in dorm.dormitories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DormitoryTile(
                dormitory: dormitory,
                isCurrent: dorm.currentDormitory?.id == dormitory.id,
                canDelete: dormitory.creatorId == currentUserId,
                onTap: () => _openDormitory(context, dormitory),
                onDelete: dormitory.creatorId == currentUserId
                    ? () => _confirmDeleteDormitory(context, dormitory)
                    : null,
              ),
            ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await context.read<AuthController>().signOut();
            context.read<DormController>().reset();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}

class _DormitoryTile extends StatelessWidget {
  const _DormitoryTile({
    required this.dormitory,
    required this.isCurrent,
    required this.canDelete,
    required this.onTap,
    this.onDelete,
  });

  final Dormitory dormitory;
  final bool isCurrent;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: isCurrent ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.home_work_outlined,
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(dormitory.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '邀请码 ${dormitory.inviteCode}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              if (canDelete && onDelete != null) ...[
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('删除'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
