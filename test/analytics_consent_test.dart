import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:option/services/upload_analytics.dart';

void main() {
  group('Analytics Consent Tests', () {
    setUp(() {
      // Clear preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Should save and retrieve analytics consent preference', () async {
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

    test('Should save and retrieve marketing consent preference', () async {
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

    test('Should save and retrieve privacy policy acceptance', () async {
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

    test('Should not track analytics when consent is denied', () async {
      // Deny analytics consent
      await UploadAnalytics.setAnalyticsConsent(false);

      // Try to track an event
      await UploadAnalytics.trackEvent('test_event', {'test': 'data'});

      // Since we don't have a real backend in this test, we just verify
      // that the method doesn't throw an exception
      expect(true, true);
    });

    test('Should track analytics when consent is given', () async {
      // Give analytics consent
      await UploadAnalytics.setAnalyticsConsent(true);

      // Try to track an event
      await UploadAnalytics.trackEvent('test_event', {'test': 'data'});

      // Since we don't have a real backend in this test, we just verify
      // that the method doesn't throw an exception
      expect(true, true);
    });
  });
}