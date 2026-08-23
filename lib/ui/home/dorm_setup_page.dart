import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../../state/dorm_controller.dart';
import '../widgets/member_avatar.dart';
import 'create_dorm_page.dart';
import 'join_dorm_page.dart';

class DormSetupPage extends StatelessWidget {
  const DormSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final dorm = context.watch<DormController>();
    final profile = auth.profile;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              MemberAvatar(
                name: profile?.username ?? '我',
                imageUrl: profile?.avatarUrl,
                size: 44,
                seed: profile?.id ?? '',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '你好，${profile?.username ?? '成员'}',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text('先创建一个宿舍，或加入舍友的宿舍。', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('还没有宿舍群组', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '创建后会自动生成邀请码，舍友凭邀请码加入，大家共享同一份账单。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: dorm.isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateDormPage(),
                      ),
                    );
                  },
            icon: const Icon(Icons.add_home_work_outlined),
            label: const Text('创建宿舍'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: dorm.isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const JoinDormPage(),
                      ),
                    );
                  },
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('加入已有宿舍'),
          ),
          if (dorm.isLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (dorm.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              dorm.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () async {
              await context.read<AuthController>().signOut();
              context.read<DormController>().reset();
            },
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}

