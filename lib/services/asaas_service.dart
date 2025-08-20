import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uber_clone/config/app_config.dart';
import 'package:uber_clone/exceptions/app_exceptions.dart';

class AsaasService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _http;

  AsaasService({http.Client? httpClient})
      : _baseUrl = AppConfig.asaasBaseUrl,
        _apiKey = AppConfig.asaasApiKey,
        _http = httpClient ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'access_token': _apiKey,
      };

  // Ensure a customer exists in Asaas by email and name
  Future<Map<String, dynamic>> ensureCustomer({
    required String name,
    required String email,
    String? cpfCnpj,
    String? mobilePhone,
  }) async {
    try {
      final existing = await _searchCustomerByEmail(email);
      if (existing != null) return existing;

      final uri = Uri.parse('$_baseUrl/customers');
      final resp = await _http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          if (cpfCnpj != null) 'cpfCnpj': cpfCnpj,
          if (mobilePhone != null) 'mobilePhone': mobilePhone,
        }),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw NetworkException('Asaas error (${resp.statusCode}): ${resp.body}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Falha ao garantir cliente Asaas: $e');
    }
  }

  Future<Map<String, dynamic>?> _searchCustomerByEmail(String email) async {
    final uri = Uri.parse('$_baseUrl/customers?email=$email');
    final resp = await _http.get(uri, headers: _headers);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (data['data'] as List?) ?? const [];
      if (items.isNotEmpty) return items.first as Map<String, dynamic>;
      return null;
    }
    throw NetworkException('Asaas error (${resp.statusCode}): ${resp.body}');
  }
}