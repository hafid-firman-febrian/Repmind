import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/repmind_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const items = [
    RepmindNavItem(icon: Icons.home_rounded, label: 'Home', tone: NavTone.lime),
    RepmindNavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Plan',
      tone: NavTone.lime,
    ),
    RepmindNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Coach',
      tone: NavTone.violet,
      enabled: false,
    ),
    RepmindNavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Progress',
      tone: NavTone.orange,
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: navigationShell,
    bottomNavigationBar: RepmindNavBar(
      items: items,
      currentIndex: navigationShell.currentIndex,
      onSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}
