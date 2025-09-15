import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A robust animation widget that tries multiple formats as fallbacks
/// Priority: Lottie JSON -> GIF -> WebM -> Static fallback
class AdaptiveAnimationWidget extends StatefulWidget {
  final String
  basePath; // Path without extension (e.g., 'assets/lotte_animations/start')
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;
  final Widget? staticFallback;

  const AdaptiveAnimationWidget({
    super.key,
    required this.basePath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
    this.staticFallback,
  });

  @override
  State<AdaptiveAnimationWidget> createState() =>
      _AdaptiveAnimationWidgetState();
}

class _AdaptiveAnimationWidgetState extends State<AdaptiveAnimationWidget> {
  int _currentFormat = 0; // 0: Lottie, 1: GIF, 2: WebM, 3: Static fallback

  @override
  Widget build(BuildContext context) {
    switch (_currentFormat) {
      case 0:
        return _buildLottieAnimation();
      case 1:
        return _buildGifAnimation();
      case 2:
        return _buildWebMAnimation();
      default:
        return _buildStaticFallback();
    }
  }

  Widget _buildLottieAnimation() {
    return Lottie.asset(
      '${widget.basePath}.json',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: widget.repeat,
      animate: widget.animate,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Lottie animation failed, trying GIF: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentFormat = 1; // Try GIF next
            });
          }
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGifAnimation() {
    return Image.asset(
      '${widget.basePath}.gif',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('GIF animation failed, trying WebM: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentFormat = 2; // Try WebM next
            });
          }
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWebMAnimation() {
    // For WebM support, we'll use a simple Image.asset approach
    // Note: Flutter has limited WebM support, so this might also fail
    return Image.asset(
      '${widget.basePath}.webm',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('WebM animation failed, using static fallback: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentFormat = 3; // Use static fallback
            });
          }
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStaticFallback() {
    if (widget.staticFallback != null) {
      return widget.staticFallback!;
    }

    // Default healthcare-themed fallback
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2), // Medical blue
            Color(0xFF7BB3F0),
            Color(0xFF4A90E2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 80),
    );
  }
}

/// Optimized version that directly uses GIF for better performance
class SimpleGifWidget extends StatelessWidget {
  final String gifPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const SimpleGifWidget({
    super.key,
    required this.gifPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      gifPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('GIF failed to load: $error');
        return fallback ?? _buildDefaultFallback();
      },
    );
  }

  Widget _buildDefaultFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF7BB3F0), Color(0xFF4A90E2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 80),
    );
  }
}
