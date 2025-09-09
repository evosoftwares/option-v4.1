import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences and consent settings
class UserPreferencesService {
  static const String _keyAnalyticsConsent = 'user_consent_analytics';
  static const String _keyMarketingConsent = 'user_consent_marketing';
  static const String _keyPrivacyPolicyAccepted = 'user_privacy_policy_accepted';
  static const String _keyConsentTimestamp = 'user_consent_timestamp';

  /// Singleton instance
  static final UserPreferencesService _instance = UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();

  /// Get SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Set analytics consent
  Future<bool> setAnalyticsConsent(bool consent) async {
    final prefs = await _getPrefs();
    final result = await prefs.setBool(_keyAnalyticsConsent, consent);
    
    // If consent is given, also save the timestamp
    if (consent) {
      await prefs.setString(_keyConsentTimestamp, DateTime.now().toIso8601String());
    }
    
    return result;
  }

  /// Get analytics consent
  Future<bool> getAnalyticsConsent() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyAnalyticsConsent) ?? false;
  }

  /// Set marketing consent
  Future<bool> setMarketingConsent(bool consent) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keyMarketingConsent, consent);
  }

  /// Get marketing consent
  Future<bool> getMarketingConsent() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyMarketingConsent) ?? false;
  }

  /// Set privacy policy acceptance
  Future<bool> setPrivacyPolicyAccepted(bool accepted) async {
    final prefs = await _getPrefs();
    return await prefs.setBool(_keyPrivacyPolicyAccepted, accepted);
  }

  /// Get privacy policy acceptance
  Future<bool> getPrivacyPolicyAccepted() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyPrivacyPolicyAccepted) ?? false;
  }

  /// Get consent timestamp
  Future<DateTime?> getConsentTimestamp() async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getString(_keyConsentTimestamp);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Check if user has given any consent
  Future<bool> hasGivenAnyConsent() async {
    final analyticsConsent = await getAnalyticsConsent();
    final marketingConsent = await getMarketingConsent();
    final privacyAccepted = await getPrivacyPolicyAccepted();
    
    return analyticsConsent || marketingConsent || privacyAccepted;
  }

  /// Clear all consent data
  Future<bool> clearAllConsentData() async {
    final prefs = await _getPrefs();
    final result1 = await prefs.remove(_keyAnalyticsConsent);
    final result2 = await prefs.remove(_keyMarketingConsent);
    final result3 = await prefs.remove(_keyPrivacyPolicyAccepted);
    final result4 = await prefs.remove(_keyConsentTimestamp);
    
    return result1 && result2 && result3 && result4;
  }
}