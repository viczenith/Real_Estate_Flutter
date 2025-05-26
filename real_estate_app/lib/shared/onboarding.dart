import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Discover Dream Homes",
      description:
          "Explore luxury properties with 360° virtual tours and AI-powered recommendations.",
      lottieJson: "assets/animations/house.json",
      color: const Color(0xFF2A2D3E),
    ),
    OnboardingPage(
      title: "Smart Search & Filters",
      description:
          "Find your perfect home using advanced filters and machine learning suggestions.",
      lottieJson: "assets/animations/house2.json",
      color: const Color(0xFF1F212E),
    ),
    OnboardingPage(
      title: "Virtual Reality Tours",
      description:
          "Experience properties in immersive VR with real-time agent collaboration.",
      lottieJson: "assets/animations/house3.json",
      color: const Color(0xFF252837),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),
          _buildAppBar(),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Page Layout with Lottie Animation
  Widget _buildPage(OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [page.color, page.color.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Hero(
                tag: page.title,
                child: Lottie.asset(
                  page.lottieJson,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildContent(page),
          ),
        ],
      ),
    );
  }

  /// Content Section with Title and Description
  Widget _buildContent(OnboardingPage page) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// App Bar with Skip Button
  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedOpacity(
              opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: () => _controller.animateToPage(
                  _pages.length - 1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Footer with Page Indicator and Navigation Button
  Widget _buildFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
          ),
        ),
        child: Column(
          children: [
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: const ExpandingDotsEffect(
                dotWidth: 12,
                dotHeight: 12,
                expansionFactor: 3,
                spacing: 8,
                activeDotColor: Color(0xFF6C5CE7),
                dotColor: Colors.white30,
              ),
            ),
            const SizedBox(height: 30),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: _currentPage == _pages.length - 1
                  ? _buildGetStartedButton()
                  : _buildNextButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// Next Button
  Widget _buildNextButton() {
    return FloatingActionButton(
      key: const ValueKey('Next'),
      onPressed: () => _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
      backgroundColor: const Color(0xFF6C5CE7),
      elevation: 8,
      child: const Icon(Icons.arrow_forward, size: 28, color: Colors.white),
    );
  }

  /// Get Started Button
  Widget _buildGetStartedButton() {
    return SizedBox(
      key: const ValueKey('GetStarted'),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF6C5CE7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: const Color(0xFF6C5CE7).withOpacity(0.5),
        ),
        child: const Text(
          "Get Started",
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String lottieJson;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.lottieJson,
    required this.color,
  });
}