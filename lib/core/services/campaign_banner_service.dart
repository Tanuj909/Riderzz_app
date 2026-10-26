import 'package:flutter/material.dart';

/// Centralized service to manage and display the app launch campaign banner
/// for both Customers and Drivers.
///
/// Ensures the banner is only shown once per app launch/session and not repeatedly.
class CampaignBannerService {
  CampaignBannerService._();

  static bool _hasShownThisSession = false;
  static bool _isDialogVisible = false;

  /// Check whether the campaign banner has already been shown in this app session.
  static bool get hasShownThisSession => _hasShownThisSession;

  /// Resets the session flag (e.g. on logout or app re-initialization).
  static void resetSession() {
    _hasShownThisSession = false;
  }

  /// Displays the campaign banner popup if it hasn't been shown yet in this session.
  static Future<void> showCampaignBannerIfNeeded(BuildContext context) async {
    if (_hasShownThisSession || _isDialogVisible) return;
    if (!context.mounted) return;

    _hasShownThisSession = true;
    _isDialogVisible = true;

    try {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Campaign Banner',
        barrierColor: Colors.black.withValues(alpha: 0.68),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return const CampaignBannerDialog();
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curve),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[CAMPAIGN_BANNER] Error presenting banner: $e');
    } finally {
      _isDialogVisible = false;
    }
  }
}

/// A modern, responsive campaign banner popup with clear close controls.
class CampaignBannerDialog extends StatelessWidget {
  const CampaignBannerDialog({super.key});

  static const String campaignImagePath = 'assets/images/campaign.png';
  // Aspect ratio of assets/images/campaign.png (941 x 1671)
  static const double imageAspectRatio = 941 / 1671;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Responsive sizing logic
    final maxAvailableWidth = (screenWidth * 0.85).clamp(280.0, 390.0);
    // Reserve vertical space for status bar, bottom padding and close button
    final maxAvailableHeight = screenHeight * 0.70;

    double dialogWidth = maxAvailableWidth;
    double dialogHeight = dialogWidth / imageAspectRatio;

    if (dialogHeight > maxAvailableHeight) {
      dialogHeight = maxAvailableHeight;
      dialogWidth = dialogHeight * imageAspectRatio;
    }

    return PopScope(
      canPop: true,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Campaign Poster ──
                Container(
                  width: dialogWidth,
                  height: dialogHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      campaignImagePath,
                      width: dialogWidth,
                      height: dialogHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('[CAMPAIGN_BANNER] Failed to load image: $error');
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Additional Bottom Circular Close Button ──
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
