import 'package:flutter/material.dart';

import '../../core/app_config.dart';

class SetupGuidePage extends StatelessWidget {
  const SetupGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String, String)>[
      (
        Icons.cloud_outlined,
        '创建 Supabase 项目',
        '打开 supabase.com 注册并创建免费项目，然后在项目设置中复制项目 URL 和 anon key。',
      ),
      (
        Icons.data_object_rounded,
        '导入数据库结构',
        '打开 SQL Editor，将项目内 supabase/schema.sql 的内容整体执行一次。',
      ),
      (
        Icons.build_rounded,
        '配置构建参数',
        '构建 APK 时传入 SUPABASE_URL 和 SUPABASE_ANON_KEY，或使用 GitHub Actions 的仓库 Secrets。',
      ),
      (
        Icons.phone_android_rounded,
        '安装到手机',
        '把生成的 app-release.apk 发送到手机并允许安装未知来源应用即可。',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('初始化配置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'ourbills 需要连接你的云数据库',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '当前构建还没有写入 Supabase 配置。完成后重新打包即可正常使用。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            for (var index = 0; index < steps.length; index++) ...[
              _StepTile(
                number: index + 1,
                icon: steps[index].$1,
                title: steps[index].$2,
                description: steps[index].$3,
              ),
              if (index < steps.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
            Text(
              '当前 Supabase URL：\n${AppConfig.supabaseUrl}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$number. $title',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
