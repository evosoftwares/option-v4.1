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

  // ========== PAYMENT METHODS ==========

  /// Create a PIX payment
  Future<Map<String, dynamic>> createPixPayment({
    required String customerId,
    required double amount,
    required String description,
    int dueInMinutes = 30,
    String? externalReference,
  }) async {
    try {
      final dueDate = DateTime.now().add(Duration(minutes: dueInMinutes));
      final payload = {
        'customer': customerId,
        'billingType': 'PIX',
        'value': amount,
        'description': description,
        'dueDate': dueDate.toIso8601String().split('T')[0],
        'externalReference': externalReference,
        'postalService': false,
      };

      final uri = Uri.parse('$_baseUrl/payments');
      final resp = await _http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw NetworkException('Erro ao criar pagamento PIX: ${resp.body}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Falha ao criar pagamento PIX: $e');
    }
  }

  /// Get PIX QR Code for a payment
  Future<Map<String, dynamic>?> getPixQrCode(String paymentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/payments/$paymentId/pixQrCode');
      final resp = await _http.get(uri, headers: _headers);
      
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else if (resp.statusCode == 404) {
        return null; // QR Code not available yet
      }
      throw NetworkException('Erro ao obter QR Code PIX: ${resp.body}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Falha ao obter QR Code PIX: $e');
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/payments/$paymentId');
      final resp = await _http.get(uri, headers: _headers);
      
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw NetworkException('Erro ao obter status do pagamento: ${resp.body}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Falha ao obter status do pagamento: $e');
    }
  }

  /// Cancel a payment
  Future<Map<String, dynamic>> cancelPayment(String paymentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/payments/$paymentId/cancel');
      final resp = await _http.post(uri, headers: _headers);
      
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw NetworkException('Erro ao cancelar pagamento: ${resp.body}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Falha ao cancelar pagamento: $e');
    }
  }

  /// Create a credit card payment (for future implementation)
  Future<Map<String, dynamic>> createCreditCardPayment({
    required String customerId,
    required double amount,
    required String description,
    required Map<String, dynamic> creditCardData,
    String? externalReference,
  }) async {
    try {
      final payload = {
        'customer': customerId,
        'billingType': 'CREDIT_CARD',
        'value': amount,
        'description': description,
        'externalReference': externalReference,
        'creditCard': creditCardData,
      };

      final uri = Uri.parse('$_baseUrl/payments');
      final resp = await _http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw NetworkException('Erro ao criar pagamento com cartão: ${resp.body}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Falha ao criar pagamento com cartão: $e');
    }
  }

  // Expose base URL and headers for other services if needed
  String get baseUrl => _baseUrl;
  Map<String, String> get headers => _headers;
}