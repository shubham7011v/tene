import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tene/services/tene_service.dart';

/// A dialog that shows the status of a Tene send operation
class TeneStatusDialog extends StatelessWidget {
  final SendTeneResult result;
  final VoidCallback? onDismiss;

  const TeneStatusDialog({super.key, required this.result, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status icon or animation
            _buildStatusVisual(),
            const SizedBox(height: 16),

            // Status message
            Text(
              result.success ? 'Tene Sent!' : 'Could Not Send Tene',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: result.success ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            // Detailed message
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Dismiss button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismiss != null) {
                    onDismiss!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(result.success ? 'Great!' : 'OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusVisual() {
    if (result.success) {
      // Success animation
      return Lottie.asset(
        'assets/animations/success.json',
        width: 120,
        height: 120,
        repeat: false,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.check_circle, color: Colors.green, size: 80);
        },
      );
    } else if (result.message.contains('already sent')) {
      // Waiting animation
      return Lottie.asset(
        'assets/animations/waiting.json',
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.hourglass_top, color: Colors.amber, size: 80);
        },
      );
    } else {
      // Error animation
      return Lottie.asset(
        'assets/animations/error.json',
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red, size: 80);
        },
      );
    }
  }
}

/// Shows a Tene status dialog
void showTeneStatusDialog(BuildContext context, SendTeneResult result, {VoidCallback? onDismiss}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TeneStatusDialog(result: result, onDismiss: onDismiss),
  );
}
