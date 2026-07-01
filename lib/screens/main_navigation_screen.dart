import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'pre_stock_screen.dart';
import 'utilities_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PreStockScreen(type: 'kratom'),
    PreStockScreen(type: 'syrup'),
    UtilitiesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF10B981), // Emerald green
          unselectedItemColor: Colors.white60,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF10B981)),
              label: 'ລາຍຈ່າຍ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_cafe_outlined),
              activeIcon: Icon(Icons.local_cafe_rounded, color: Color(0xFF10B981)),
              label: 'ສາງ ທ້ອມ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              activeIcon: Icon(Icons.water_drop_rounded, color: Color(0xFF10B981)),
              label: 'ສາງນ້ຳຢາ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.electric_bolt_outlined),
              activeIcon: Icon(Icons.electric_bolt_rounded, color: Color(0xFF10B981)),
              label: 'ໄຟ - ນ້ຳ',
            ),
          ],
        ),
      ),
    );
  }
}
