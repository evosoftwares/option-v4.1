import 'package:flutter/material.dart';
import 'upload_analytics.dart';

class ConsentDemoScreen extends StatefulWidget {
  const ConsentDemoScreen({super.key});

  @override
  _ConsentDemoScreenState createState() => _ConsentDemoScreenState();
}

class _ConsentDemoScreenState extends State<ConsentDemoScreen> {
  bool _hasAnalyticsConsent = false;
  bool _hasMarketingConsent = false;
  bool _hasAcceptedPrivacyPolicy = false;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    final analyticsConsent = await UploadAnalytics.hasAnalyticsConsent();
    final marketingConsent = await UploadAnalytics.hasMarketingConsent();
    final privacyPolicyAccepted = await UploadAnalytics.hasAcceptedPrivacyPolicy();

    setState(() {
      _hasAnalyticsConsent = analyticsConsent;
      _hasMarketingConsent = marketingConsent;
      _hasAcceptedPrivacyPolicy = privacyPolicyAccepted;
    });
  }

  Future<void> _toggleAnalyticsConsent(bool value) async {
    await UploadAnalytics.setAnalyticsConsent(value);
    setState(() {
      _hasAnalyticsConsent = value;
    });
    
    // Track the consent change event
    await UploadAnalytics.trackEvent('analytics_consent_changed', {
      'consent_given': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _toggleMarketingConsent(bool value) async {
    await UploadAnalytics.setMarketingConsent(value);
    setState(() {
      _hasMarketingConsent = value;
    });
    
    // Track the consent change event
    await UploadAnalytics.trackEvent('marketing_consent_changed', {
      'consent_given': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _togglePrivacyPolicyAcceptance(bool value) async {
    await UploadAnalytics.setPrivacyPolicyAccepted(value);
    setState(() {
      _hasAcceptedPrivacyPolicy = value;
    });
    
    // Track the policy acceptance event
    await UploadAnalytics.trackEvent('privacy_policy_accepted', {
      'accepted': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Consentimentos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gerencie suas preferências de privacidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Coleta de Dados Analíticos'),
                subtitle: const Text(
                    'Permite que coletemos dados para melhorar sua experiência'),
                trailing: Switch(
                  value: _hasAnalyticsConsent,
                  onChanged: _toggleAnalyticsConsent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Comunicações de Marketing'),
                subtitle: const Text(
                    'Permite que enviemos promoções e ofertas especiais'),
                trailing: Switch(
                  value: _hasMarketingConsent,
                  onChanged: _toggleMarketingConsent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Política de Privacidade'),
                subtitle: const Text('Aceite nossa política de privacidade'),
                trailing: Switch(
                  value: _hasAcceptedPrivacyPolicy,
                  onChanged: _togglePrivacyPolicyAcceptance,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Status Atual:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Analytics: ${_hasAnalyticsConsent ? "Permitido" : "Negado"}'),
            Text('Marketing: ${_hasMarketingConsent ? "Permitido" : "Negado"}'),
            Text(
                'Política de Privacidade: ${_hasAcceptedPrivacyPolicy ? "Aceita" : "Não Aceita"}'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Simulate tracking an event
                UploadAnalytics.trackEvent('button_clicked', {
                  'button_name': 'demo_button',
                  'screen': 'consent_demo',
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Evento registrado! Verifique o console.'),
                  ),
                );
              },
              child: const Text('Testar Registro de Evento'),
            ),
          ],
        ),
      ),
    );
  }
}