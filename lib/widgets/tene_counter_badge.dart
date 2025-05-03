import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';

/// A widget that displays a badge with the count of unviewed Tenes
class TeneCounterBadge extends ConsumerWidget {
  final Widget child;
  final double badgeSize;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const TeneCounterBadge({
    super.key,
    required this.child,
    this.badgeSize = 20.0,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the new StreamProvider for unviewed Tenes by phone number
    final tenesAsyncValue = ref.watch(unviewedTenesByPhoneProvider);

    return tenesAsyncValue.when(
      data: (tenes) {
        final count = tenes.length;

        // If no unviewed Tenes, just return the child
        if (count == 0) {
          return child;
        }

        // Return child with badge
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The wrapped widget (e.g., an icon)
            GestureDetector(onTap: onTap, child: child),

            // Badge with count
            Positioned(
              right: -5,
              top: -5,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  height: badgeSize,
                  width: badgeSize,
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: badgeSize * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => child, // Show without badge while loading
      error: (_, __) => child, // Show without badge on error
    );
  }
}
