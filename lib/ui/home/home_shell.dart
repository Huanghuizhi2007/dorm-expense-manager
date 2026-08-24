import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../data/update_service.dart';
import '../../state/dorm_controller.dart';
import '../calendar/calendar_page.dart';
import '../expenses/expense_edit_page.dart';
import '../expenses/expense_list_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../stats/stats_page.dart';
import 'dorm_setup_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_updateChecked || kIsWeb) return;
    _updateChecked = true;

    final update = await UpdateService.checkLatest();
    if (update == null || !UpdateService.isNewer(update.version, AppInfo.version)) {
      return;
    }
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissed =
        prefs.getBool('update_dismissed_${update.version}') ?? false;
    if (dismissed) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Text(
          'ourbills ${update.version} 已经发布，点击“去下载”获取最新版。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(
                'update_dismissed_${update.version}',
                true,
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(
                'update_dismissed_${update.version}',
                true,
              );
              if (context.mounted) Navigator.of(context).pop();
              await launchUrl(
                Uri.parse(update.url),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('去下载'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dorm = context.watch<DormController>();
    final hasDorm = dorm.currentDormitory != null;

    return Scaffold(
      body: SafeArea(
        child: hasDorm
            ? IndexedStack(
                index: _index,
                children: const <Widget>[
                  HomePage(),
                  ExpenseListPage(),
                  CalendarPage(),
                  StatsPage(),
                  ProfilePage(),
                ],
              )
            : const DormSetupPage(),
      ),
      floatingActionButton: hasDorm && (_index == 0 || _index == 1)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExpenseEditPage(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('记一笔'),
            )
          : null,
      bottomNavigationBar: hasDorm
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) {
                setState(() {
                  _index = value;
                });
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: '账单',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: '日历',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insert_chart_outlined_rounded),
                  selectedIcon: Icon(Icons.insert_chart_rounded),
                  label: '统计',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            )
          : null,
    );
  }
}
