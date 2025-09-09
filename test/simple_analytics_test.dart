import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:option/services/upload_analytics.dart';

void main() {
  group('Simple Analytics Tests', () {
    setUp(() {
      // Clear preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Analytics consent methods should work correctly', () async {
      // Initially should be false
      bool initialConsent = await UploadAnalytics.hasAnalyticsConsent();
      expect(initialConsent, false);

      // Set consent to true
      bool saved = await UploadAnalytics.setAnalyticsConsent(true);
      expect(saved, true);

      // Verify consent is now true
      bool updatedConsent = await UploadAnalytics.hasAnalyticsConsent();
      expect(updatedConsent, true);
    });

    test('Marketing consent methods should work correctly', () async {
      // Initially should be false
      bool initialConsent = await UploadAnalytics.hasMarketingConsent();
      expect(initialConsent, false);

      // Set consent to true
      bool saved = await UploadAnalytics.setMarketingConsent(true);
      expect(saved, true);

      // Verify consent is now true
      bool updatedConsent = await UploadAnalytics.hasMarketingConsent();
      expect(updatedConsent, true);
    });

    test('Privacy policy acceptance methods should work correctly', () async {
      // Initially should be false
      bool initialAcceptance = await UploadAnalytics.hasAcceptedPrivacyPolicy();
      expect(initialAcceptance, false);

      // Accept privacy policy
      bool saved = await UploadAnalytics.setPrivacyPolicyAccepted(true);
      expect(saved, true);

      // Verify policy is now accepted
      bool updatedAcceptance = await UploadAnalytics.hasAcceptedPrivacyPolicy();
      expect(updatedAcceptance, true);
    });
  });
}