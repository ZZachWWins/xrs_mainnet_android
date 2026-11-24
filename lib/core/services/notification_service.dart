import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationToast(
        message: message,
        isError: isError,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

class _NotificationToast extends StatefulWidget {
  final String message;
  final bool isError;

  const _NotificationToast({
    required this.message,
    this.isError = false,
  });

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandMidnight.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isError 
                    ? AppColors.error.withValues(alpha: 0.5) 
                    : AppColors.brandVibrant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: widget.isError ? AppColors.error : AppColors.brandVibrant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .slideY(begin: -1, end: 0, curve: Curves.easeOutBack, duration: 400.ms)
        .fadeIn(duration: 300.ms)
        .then(delay: 2000.ms) // Wait before exit animation
        .slideY(begin: 0, end: -1, curve: Curves.easeInBack, duration: 300.ms)
        .fadeOut(duration: 300.ms),
      ),
    );
  }
}
