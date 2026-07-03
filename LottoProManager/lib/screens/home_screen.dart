import 'package:flutter/material.dart';

import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';
import 'search_screen.dart';
import 'tickets_screen.dart';
import 'winning_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.people_outline), label: 'Customers'),
    NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), label: 'Tickets'),
    NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Winners'),
    NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Payments'),
    NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
  ];

  static const _screens = <Widget>[
    DashboardScreen(),
    CustomersScreen(),
    TicketsScreen(),
    WinningScreen(),
    PaymentsScreen(),
    ReportsScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              extended: MediaQuery.sizeOf(context).width >= 1180,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: _destinations
                  .map(
                    (destination) => NavigationRailDestination(
                      icon: destination.icon,
                      label: Text(destination.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: _destinations,
      ),
    );
  }
}
