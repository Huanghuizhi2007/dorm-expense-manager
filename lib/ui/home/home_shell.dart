import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/dorm_controller.dart';
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

