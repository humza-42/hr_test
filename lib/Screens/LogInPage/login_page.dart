import 'package:flutter/material.dart';

import 'package:hr_test/Widgets/LogIn_Page/login_form.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback? onThemeToggle;

  const LoginPage({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // For desktop (width > 1024px): Show split-screen layout
          if (screenWidth > 1024) {
            return Row(
              children: [
                // Left panel (60% width)
                Expanded(
                  flex: 6,
                  child: _buildPromotionalPanel(
                    context,
                    screenHeight,
                    screenWidth,
                  ),
                ),
                // Right panel (40% width)
                Expanded(
                  flex: 4,
                  child: _buildLoginPanel(context, screenWidth, screenHeight),
                ),
              ],
            );
          } else if (screenWidth > 768) {
            // Tablet: Still split but adjusted proportions
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildPromotionalPanel(
                    context,
                    screenHeight,
                    screenWidth,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _buildLoginPanel(context, screenWidth, screenHeight),
                ),
              ],
            );
          } else {
            // Mobile: Stack panels vertically
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Column(
                  children: [
                    Container(
                      height: screenHeight * 0.45,
                      child: _buildPromotionalPanel(
                        context,
                        screenHeight * 0.45,
                        screenWidth,
                      ),
                    ),
                    _buildLoginPanel(context, screenWidth, screenHeight),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPromotionalPanel(
    BuildContext context,
    double minHeight,
    double screenWidth,
  ) {
    final isDesktop = screenWidth > 1024;
    final horizontalPadding = isDesktop
        ? 80.0
        : (screenWidth > 768 ? 50.0 : 30.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red, Colors.redAccent],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 60,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo/Heading with better styling
              Image.asset(
                'assets/images/2.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BITSTORM SOLUTIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              // Title with better typography
              const Text(
                'Bitstorm HR\nManagement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Description with better styling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Welcome to your HR portal. Manage your attendance, leaves, schedules, and more with ease and security.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 17,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 80),
              // Feature icons with labels - improved design
              _buildFeatureIcons(screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcons(double screenWidth) {
    final isDesktop = screenWidth > 1024;
    final iconSpacing = isDesktop ? 60.0 : (screenWidth > 768 ? 45.0 : 25.0);

    return Column(
      children: [
        // Icons row with better spacing
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeatureIconCircle(Icons.check_circle_outline),
            SizedBox(width: iconSpacing),
            _buildFeatureIconCircle(Icons.calendar_today_outlined),
            SizedBox(width: iconSpacing),
            _buildFeatureIconCircle(Icons.access_time_outlined),
          ],
        ),
        const SizedBox(height: 24),
        // Labels row - wrap on smaller screens
        screenWidth > 600
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureLabel('Attendance'),
                  SizedBox(width: iconSpacing),
                  _buildFeatureLabel('Leave Management'),
                  SizedBox(width: iconSpacing),
                  _buildFeatureLabel('Time Tracking'),
                ],
              )
            : Wrap(
                alignment: WrapAlignment.center,
                spacing: iconSpacing,
                runSpacing: 12,
                children: [
                  _buildFeatureLabel('Attendance'),
                  _buildFeatureLabel('Leave Management'),
                  _buildFeatureLabel('Time Tracking'),
                ],
              ),
      ],
    );
  }

  Widget _buildFeatureIconCircle(IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 38),
    );
  }

  Widget _buildFeatureLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.95),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoginPanel(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    final padding = screenWidth > 1024
        ? 60.0
        : (screenWidth > 768 ? 40.0 : 24.0);

    return Container(
      height: screenHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: screenWidth > 1024
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: LoginForm(onThemeToggle: onThemeToggle),
                )
              : SizedBox(
                  width: double.infinity,
                  child: LoginForm(onThemeToggle: onThemeToggle),
                ),
        ),
      ),
    );
  }
}
