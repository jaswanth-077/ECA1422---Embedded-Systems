import 'package:flutter/material.dart';
import '../repositories/sensor_repository.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'device_screen.dart';

class MainScreen extends StatefulWidget {
  final SensorRepository repository;

  const MainScreen({
    super.key,
    required this.repository,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(repository: widget.repository),
      HistoryScreen(repository: widget.repository),
      DeviceScreen(repository: widget.repository),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.developer_board_rounded),
              activeIcon: Icon(Icons.developer_board_rounded),
              label: 'Device',
            ),
          ],
        ),
      ),
    );
  }
}
