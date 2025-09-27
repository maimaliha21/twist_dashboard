// lib/pages/DashboardLayout.dart
// import 'package:flutter/material.dart';
// import 'package:twist_dashboard/pages/home.dart';
// import 'package:twist_dashboard/pages/BanksDashboard.dart';
// import 'package:twist_dashboard/pages/TerminalsDashboard.dart';
// import 'package:twist_dashboard/pages/companies_dashboard.dart';
// import 'package:twist_dashboard/theme/AppColors.dart';

import 'package:flutter/material.dart';
import 'package:twist_dashboard/pages/BanksDashboard.dart';
import 'package:twist_dashboard/pages/Home.dart';
import 'package:twist_dashboard/pages/TerminalsDashboard.dart';
import 'package:twist_dashboard/pages/companies_dashboard.dart';
import 'package:twist_dashboard/theme/AppColors.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;
  final _menuItems = ["Home", "Banks", "Terminals", "Companies & Branches"];
  double sidebarWidth = 200;
  bool isSidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSidebarOpen ? sidebarWidth : 0,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: isSidebarOpen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance,
                                  size: 40, color: Colors.black),
                              const SizedBox(height: 4),
                              Text(
                                "Twist",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(top: 8),
                          children: _buildNavigationItems(),
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Title
                      Text(
                        _menuItems[_selectedIndex],
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // Settings / Menu Icon
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          setState(() {
                            isSidebarOpen = !isSidebarOpen;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _getSelectedPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavigationItems() {
    return [
      _buildNavItem(0, Icons.home, "Home"),
      _buildNavItem(1, Icons.account_balance, "Banks"),
      _buildNavItem(2, Icons.terminal, "Terminals"),
      _buildNavItem(3, Icons.business, "Companies & Branches"),
    ];
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color.fromARGB(83, 99, 99, 99).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? AppColors.secondary : AppColors.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
        dense: true,
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const BanksDashboard();
      case 2:
        return const TerminalsDashboard();
      case 3:
        return const CompaniesDashboard();
      default:
        return const HomePage();
    }
  }
}
