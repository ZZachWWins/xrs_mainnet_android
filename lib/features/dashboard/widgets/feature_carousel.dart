import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';

class FeatureBanner {
  final String title;
  final String description;
  final List<Color> gradient;
  final IconData icon;
  final String route;
  final Object? extra;

  FeatureBanner({
    required this.title,
    required this.description,
    required this.gradient,
    required this.icon,
    required this.route,
    this.extra,
  });
}

class FeatureCarousel extends ConsumerStatefulWidget {
  const FeatureCarousel({super.key});

  @override
  ConsumerState<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends ConsumerState<FeatureCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isVisible = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final banners = [
      FeatureBanner(
        title: 'Quantum Shield',
        description: 'Secure your wallet against quantum threats.',
        gradient: [const Color(0xFF0019A5), const Color(0xFF8FA3FF)],
        icon: Icons.shield_outlined,
        route: '/quantum-shield',
      ),
      FeatureBanner(
        title: 'Private Send',
        description: 'Keep your transactions completely anonymous.',
        gradient: [const Color(0xFF0A123D), const Color(0xFF4E5BA6)],
        icon: Icons.lock_outline,
        route: '/send/input',
        extra: {'pq_mode': false}, // ZKP is the default for private send
      ),
      FeatureBanner(
        title: 'AI Agents',
        description: 'Let intelligent agents manage your assets 24/7.',
        gradient: [const Color(0xFF050B2B), const Color(0xFF00C6FF)],
        icon: Icons.psychology_outlined,
        route: '/agents/register',
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () => context.push(banner.route, extra: banner.extra),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: banner.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: banner.gradient[0].withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    banner.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner.description,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              banner.icon,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                        // Close button
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                            onPressed: () => setState(() => _isVisible = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index 
                    ? AppColors.brandVibrant 
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
