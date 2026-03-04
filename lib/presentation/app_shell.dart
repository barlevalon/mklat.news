import 'package:flutter/material.dart';
import 'screens/status_screen.dart';
import 'screens/news_screen.dart';
import 'widgets/page_indicator.dart';
import 'widgets/offline_banner.dart';
import 'widgets/resume_overlay.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: const [StatusScreen(), NewsScreen()],
                  ),
                ),
                PageIndicator(currentIndex: _currentPage, pageCount: 2),
              ],
            ),
          ),
          // Offline banner overlay at top
          const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
          // Resume overlay (covers entire screen when active)
          const ResumeOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
