import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/providers.dart';

import 'dashboard_page.dart';
import 'providers/providers_list_page.dart';
import 'users/users_list_page.dart';
import 'tickets/tickets_list_page.dart';
import '../l10n/app_localizations.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProvidersListPage(),
    const UsersListPage(),
    const TicketsListPage(),
  ];

  List<String> get _titles => [
    AppLocalizations.of(context)!.homeTitle,
    AppLocalizations.of(context)!.navProviders,
    AppLocalizations.of(context)!.navUsers,
    AppLocalizations.of(context)!.navTickets,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.2), // Blue 600
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined, color: Colors.grey),
            selectedIcon: const Icon(Icons.dashboard, color: Color(0xFF2563EB)),
            label: AppLocalizations.of(context)!.homeTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.business_outlined, color: Colors.grey),
            selectedIcon: const Icon(Icons.business, color: Color(0xFF2563EB)),
            label: AppLocalizations.of(context)!.navProviders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outlined, color: Colors.grey),
            selectedIcon: const Icon(Icons.people, color: Color(0xFF2563EB)),
            label: AppLocalizations.of(context)!.navUsers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.support_agent_outlined, color: Colors.grey),
            selectedIcon: const Icon(
              Icons.support_agent,
              color: Color(0xFF2563EB),
            ),
            label: AppLocalizations.of(context)!.navTickets,
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logoutTitle),
        content: Text(AppLocalizations.of(context)!.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(
              AppLocalizations.of(context)!.logoutButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
