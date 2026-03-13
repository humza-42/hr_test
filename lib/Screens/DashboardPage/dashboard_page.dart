import 'package:flutter/material.dart';

import '../DashboardPage/dashboardoverview.dart';
import '../LogInPage/login_page.dart';
import '../../Services/storage_service.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const DashboardPage({super.key, this.onThemeToggle});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  String _selectedMenuItem = 'Dashboard';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start activity tracking when dashboard is initialized
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // Clear stored data
      await StorageService.logout();

      // Navigate to login page
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginPage(onThemeToggle: widget.onThemeToggle),
        ),
        (route) => false,
      );
    }
  }

  // PageView controller to manage page state
  final PageController _pageController = PageController();

  // Map menu items to page indexes for PageView
  final Map<String, int> _menuItemToIndex = {
    'Dashboard': 0,
    'Attendance': 1,
    'Break Requests': 2,
    'Leave': 3,
    'Tasks': 4,
    'Analytics': 5,
    'Time Tracking': 6,
    'Remaining Hours': 7,
    'Hall of Fame': 8,
  };

  void _onMenuItemSelected(String item, {bool shouldCloseDrawer = true}) {
    setState(() {
      _selectedMenuItem = item;
    });
    if (shouldCloseDrawer) {
      Navigator.pop(
        context,
      ); // Close drawer after selection (tablet/mobile only)
    }
    // Jump to the corresponding page in PageView
    final index = _menuItemToIndex[item] ?? 0;
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF212121)
        : Colors.grey[100]!;
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            elevation: 0,
            automaticallyImplyLeading:
                !isDesktop, // Hide hamburger menu on desktop
            title: Text(
              'Bitstorm Solutions - HR System',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
            actions: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: widget.onThemeToggle ?? () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleLogout,
              ),
            ],
          ),
          body: const DashboardOverview(),
        );
      },
    );
  }
}
