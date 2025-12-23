import 'package:in_app_review/in_app_review.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  /// Requests a review if conditions are met.
  /// Conditions:
  /// 1. Not requested strictly recently (e.g. today).
  /// 2. User just had a "Happy Moment" (Speed test good, Invoice paid).
  Future<void> tryRequestReview() async {
    if (await _inAppReview.isAvailable()) {
      // Check cooldown
      final prefs = await SharedPreferences.getInstance();
      final lastRequest = prefs.getInt('last_review_request') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Cooldown: 7 days
      const cooldown = 7 * 24 * 60 * 60 * 1000;

      if (now - lastRequest > cooldown) {
        debugPrint('Review: Requesting In-App Review...');
        await _inAppReview.requestReview();
        await prefs.setInt('last_review_request', now);
      } else {
        debugPrint('Review: Cooldown active');
      }
    } else {
      debugPrint('Review: Not available');
    }
  }

  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      debugPrint('Review: Error opening store listing: $e');
    }
  }
}
