import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';

class AsaasService {

  AsaasService({http.Client? httpClient})
      : _baseUrl = AppConfig.asaasBaseUrl,
        _apiKey = AppConfig.asaasApiKey,
        _http = httpClient ?? http.Client();
  final String _baseUrl;
  final String _apiKey;
  final http.Client _http;

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
      throw const NetworkException('Erro na integração com o serviço de pagamentos. Por favor, tente novamente mais tarde.');
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
    throw const NetworkException('Erro na integração com o serviço de pagamentos. Por favor, tente novamente mais tarde.');
  }
}