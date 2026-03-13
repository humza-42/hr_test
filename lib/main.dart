import 'package:flutter/material.dart';

import 'package:hr_system_test/Screens/DashboardPage/dashboard_page.dart';
import 'package:hr_system_test/Screens/LogInPage/login_page.dart';
import 'package:hr_system_test/Services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  @override
  void dispose() {
    themeNotifier.dispose();
    super.dispose();
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => _AppNavigator(onThemeToggle: toggleTheme),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (context) => LoginPage(onThemeToggle: toggleTheme),
        );
      case '/dashboard':
        return MaterialPageRoute(
          builder: (context) => DashboardPage(onThemeToggle: toggleTheme),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => _AppNavigator(onThemeToggle: toggleTheme),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFDC2626),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[100],
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFDC2626),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF212121),
    );

    return MaterialApp(
      title: 'Bitstorm Solutions - HR System',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode:
          ThemeMode.system, // Fixed value, actual theme applied in builder
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, themeMode, _) {
            final effectiveTheme = themeMode == ThemeMode.dark
                ? darkTheme
                : lightTheme;
            return Theme(data: effectiveTheme, child: child!);
          },
        );
      },
      onGenerateRoute: _generateRoute,
      home: _AppNavigator(onThemeToggle: toggleTheme),
    );
  }
}

// Wrapper widget that maintains navigation state independently of theme changes
class _AppNavigator extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const _AppNavigator({required this.onThemeToggle});

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: StorageService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return DashboardPage(onThemeToggle: widget.onThemeToggle);
        } else {
          return LoginPage(onThemeToggle: widget.onThemeToggle);
        }
      },
    );
  }
}
