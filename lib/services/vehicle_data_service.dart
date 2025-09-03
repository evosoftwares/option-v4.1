import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_brand.dart';
import '../models/vehicle_model.dart';

class VehicleDataService {

  VehicleDataService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
    _dio.options.sendTimeout = const Duration(seconds: 5);
  }
  static const String _baseUrl = 'https://parallelum.com.br/fipe/api/v1';
  static const String _brandsKey = 'vehicle_brands';
  static const String _modelsKeyPrefix = 'vehicle_models_';
  static const Duration _cacheExpiry = Duration(days: 7);

  final Dio _dio;
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<VehicleBrand>> getBrands() async {
    try {
      await _initPrefs();
      
      final cachedData = _prefs?.getString(_brandsKey);
      final cacheTime = _prefs?.getInt('${_brandsKey}_time') ?? 0;
      final isExpired = DateTime.now().millisecondsSinceEpoch - cacheTime > _cacheExpiry.inMilliseconds;

      if (cachedData != null && !isExpired) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => VehicleBrand.fromJson(json)).toList();
      }

      final response = await _dio.get('$_baseUrl/carros/marcas');
      final List<dynamic> jsonList = response.data;
      final brands = jsonList.map((json) => VehicleBrand.fromJson(json)).toList();

      brands.sort((a, b) => a.name.compareTo(b.name));

      await _prefs?.setString(_brandsKey, json.encode(jsonList));
      await _prefs?.setInt('${_brandsKey}_time', DateTime.now().millisecondsSinceEpoch);

      return brands;
    } catch (e) {
      developer.log('Error fetching brands: $e');
      return _getFallbackBrands();
    }
  }

  Future<List<VehicleModel>> getModels(int brandId) async {
    try {
      await _initPrefs();
      
      final modelsKey = '$_modelsKeyPrefix$brandId';
      final cachedData = _prefs?.getString(modelsKey);
      final cacheTime = _prefs?.getInt('${modelsKey}_time') ?? 0;
      final isExpired = DateTime.now().millisecondsSinceEpoch - cacheTime > _cacheExpiry.inMilliseconds;

      if (cachedData != null && !isExpired) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => VehicleModel.fromJson(json, brandId)).toList();
      }

      final response = await _dio.get('$_baseUrl/carros/marcas/$brandId/modelos');
      final Map<String, dynamic> responseData = response.data;
      final List<dynamic> jsonList = responseData['modelos'];
      final models = jsonList.map((json) => VehicleModel.fromJson(json, brandId)).toList();

      models.sort((a, b) => a.name.compareTo(b.name));

      await _prefs?.setString(modelsKey, json.encode(jsonList));
      await _prefs?.setInt('${modelsKey}_time', DateTime.now().millisecondsSinceEpoch);

      return models;
    } catch (e) {
      developer.log('Error fetching models for brand $brandId: $e');
      return _getFallbackModels(brandId);
    }
  }

  Future<List<VehicleBrand>> searchBrands(String query) async {
    final brands = await getBrands();
    if (query.isEmpty) return brands;
    
    final queryLower = query.toLowerCase();
    return brands.where((brand) => 
      brand.name.toLowerCase().contains(queryLower)
    ).toList();
  }

  Future<List<VehicleModel>> searchModels(int brandId, String query) async {
    final models = await getModels(brandId);
    if (query.isEmpty) return models;
    
    final queryLower = query.toLowerCase();
    return models.where((model) => 
      model.name.toLowerCase().contains(queryLower)
    ).toList();
  }

  List<VehicleBrand> _getFallbackBrands() => const [
      // Marcas Nacionais/Principais
      VehicleBrand(id: 21, name: 'Fiat', code: '21'),
      VehicleBrand(id: 59, name: 'Volkswagen', code: '59'),
      VehicleBrand(id: 23, name: 'Chevrolet', code: '23'),
      VehicleBrand(id: 26, name: 'Hyundai', code: '26'),
      VehicleBrand(id: 56, name: 'Toyota', code: '56'),
      VehicleBrand(id: 22, name: 'Ford', code: '22'),
      VehicleBrand(id: 25, name: 'Honda', code: '25'),
      VehicleBrand(id: 30, name: 'Nissan', code: '30'),
      VehicleBrand(id: 36, name: 'Renault', code: '36'),
      VehicleBrand(id: 14, name: 'Jeep', code: '14'),
      
      // Marcas Chinesas em Crescimento
      VehicleBrand(id: 238, name: 'BYD', code: '238'),
      VehicleBrand(id: 245, name: 'Caoa Chery', code: '245'),
      VehicleBrand(id: 300, name: 'GWM', code: '300'),
      VehicleBrand(id: 301, name: 'Haval', code: '301'),
      VehicleBrand(id: 13, name: 'JAC', code: '13'),
      VehicleBrand(id: 302, name: 'Geely', code: '302'),
      VehicleBrand(id: 303, name: 'Great Wall', code: '303'),
      
      // Marcas Premium Europeias
      VehicleBrand(id: 7, name: 'BMW', code: '7'),
      VehicleBrand(id: 6, name: 'Audi', code: '6'),
      VehicleBrand(id: 18, name: 'Mercedes-Benz', code: '18'),
      VehicleBrand(id: 34, name: 'Peugeot', code: '34'),
      VehicleBrand(id: 15, name: 'Citroën', code: '15'),
      VehicleBrand(id: 24, name: 'Land Rover', code: '24'),
      VehicleBrand(id: 48, name: 'Volvo', code: '48'),
      
      // Marcas Asiáticas
      VehicleBrand(id: 27, name: 'Kia', code: '27'),
      VehicleBrand(id: 28, name: 'Mitsubishi', code: '28'),
      VehicleBrand(id: 44, name: 'Suzuki', code: '44'),
      VehicleBrand(id: 43, name: 'Subaru', code: '43'),
      VehicleBrand(id: 29, name: 'Mazda', code: '29'),
      
      // Marcas de Luxo
      VehicleBrand(id: 31, name: 'Porsche', code: '31'),
      VehicleBrand(id: 35, name: 'Ferrari', code: '35'),
      VehicleBrand(id: 40, name: 'Lamborghini', code: '40'),
      VehicleBrand(id: 41, name: 'Maserati', code: '41'),
      VehicleBrand(id: 42, name: 'Bentley', code: '42'),
      
      // Outras Marcas Presentes no Brasil
      VehicleBrand(id: 19, name: 'Mini', code: '19'),
      VehicleBrand(id: 20, name: 'Smart', code: '20'),
      VehicleBrand(id: 32, name: 'Alfa Romeo', code: '32'),
      VehicleBrand(id: 33, name: 'Dodge', code: '33'),
      VehicleBrand(id: 37, name: 'Chrysler', code: '37'),
      VehicleBrand(id: 38, name: 'Ram', code: '38'),
      VehicleBrand(id: 39, name: 'Infiniti', code: '39'),
      VehicleBrand(id: 45, name: 'Lexus', code: '45'),
      VehicleBrand(id: 46, name: 'Acura', code: '46'),
      VehicleBrand(id: 47, name: 'Genesis', code: '47'),
      
      // Marcas Emergentes e Especiais
      VehicleBrand(id: 49, name: 'Tesla', code: '49'),
      VehicleBrand(id: 50, name: 'McLaren', code: '50'),
      VehicleBrand(id: 51, name: 'Aston Martin', code: '51'),
      VehicleBrand(id: 52, name: 'Rolls-Royce', code: '52'),
      VehicleBrand(id: 53, name: 'Bugatti', code: '53'),
      VehicleBrand(id: 54, name: 'Koenigsegg', code: '54'),
      VehicleBrand(id: 55, name: 'Pagani', code: '55'),
      VehicleBrand(id: 57, name: 'Lotus', code: '57'),
      VehicleBrand(id: 58, name: 'Morgan', code: '58'),
    ];

  List<VehicleModel> _getFallbackModels(int brandId) {
    final fallbackData = {
      // === TOP 10 MARCAS MAIS VENDIDAS ===
      
      21: [ // Fiat - LÍDER EM COMERCIAIS LEVES
        const VehicleModel(id: 1, name: 'Strada', code: '1', brandId: 21), // #1 MAIS VENDIDO BRASIL 2024
        const VehicleModel(id: 2, name: 'Argo', code: '2', brandId: 21), // #5 MAIS VENDIDO
        const VehicleModel(id: 3, name: 'Mobi', code: '3', brandId: 21), // #9 MAIS VENDIDO
        const VehicleModel(id: 4, name: 'Toro', code: '4', brandId: 21), // #16 MAIS VENDIDO
        const VehicleModel(id: 5, name: 'Fastback', code: '5', brandId: 21), // #20 MAIS VENDIDO
        const VehicleModel(id: 6, name: 'Cronos', code: '6', brandId: 21), // #22 MAIS VENDIDO
        const VehicleModel(id: 7, name: 'Pulse', code: '7', brandId: 21), // #23 MAIS VENDIDO
        const VehicleModel(id: 8, name: 'Fiorino', code: '8', brandId: 21),
        const VehicleModel(id: 9, name: 'Doblo', code: '9', brandId: 21),
        const VehicleModel(id: 10, name: 'Ducato', code: '10', brandId: 21),
      ],

      59: [ // Volkswagen - LÍDER GERAL 16.99% MARKET SHARE
        const VehicleModel(id: 1, name: 'Polo', code: '1', brandId: 59), // #2 MAIS VENDIDO BRASIL
        const VehicleModel(id: 2, name: 'T-Cross', code: '2', brandId: 59), // #6 SUV MAIS VENDIDO
        const VehicleModel(id: 3, name: 'Saveiro', code: '3', brandId: 59), // #13 MAIS VENDIDO
        const VehicleModel(id: 4, name: 'Nivus', code: '4', brandId: 59), // #14 MAIS VENDIDO
        const VehicleModel(id: 5, name: 'Gol', code: '5', brandId: 59),
        const VehicleModel(id: 6, name: 'Virtus', code: '6', brandId: 59),
        const VehicleModel(id: 7, name: 'Jetta', code: '7', brandId: 59),
        const VehicleModel(id: 8, name: 'Passat', code: '8', brandId: 59),
        const VehicleModel(id: 9, name: 'Tiguan', code: '9', brandId: 59),
        const VehicleModel(id: 10, name: 'Amarok', code: '10', brandId: 59),
        const VehicleModel(id: 11, name: 'Golf', code: '11', brandId: 59),
        const VehicleModel(id: 12, name: 'Polo Track', code: '12', brandId: 59),
      ],

      23: [ // Chevrolet - 13.37% MARKET SHARE
        const VehicleModel(id: 1, name: 'Onix', code: '1', brandId: 23), // #3 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Tracker', code: '2', brandId: 23), // #7 MAIS VENDIDO  
        const VehicleModel(id: 3, name: 'Onix Plus', code: '3', brandId: 23), // #11 MAIS VENDIDO
        const VehicleModel(id: 4, name: 'S10', code: '4', brandId: 23),
        const VehicleModel(id: 5, name: 'Prisma', code: '5', brandId: 23),
        const VehicleModel(id: 6, name: 'Cruze', code: '6', brandId: 23),
        const VehicleModel(id: 7, name: 'Equinox', code: '7', brandId: 23),
        const VehicleModel(id: 8, name: 'Spin', code: '8', brandId: 23),
        const VehicleModel(id: 9, name: 'Montana', code: '9', brandId: 23),
        const VehicleModel(id: 10, name: 'Captiva', code: '10', brandId: 23),
      ],

      26: [ // Hyundai - 10.17% MARKET SHARE
        const VehicleModel(id: 1, name: 'HB20', code: '1', brandId: 26), // #4 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Creta', code: '2', brandId: 26), // #8 MAIS VENDIDO
        const VehicleModel(id: 3, name: 'HB20S', code: '3', brandId: 26), // #25 MAIS VENDIDO
        const VehicleModel(id: 4, name: 'Tucson', code: '4', brandId: 26),
        const VehicleModel(id: 5, name: 'ix35', code: '5', brandId: 26),
        const VehicleModel(id: 6, name: 'Elantra', code: '6', brandId: 26),
        const VehicleModel(id: 7, name: 'Santa Fe', code: '7', brandId: 26),
        const VehicleModel(id: 8, name: 'HB20X', code: '8', brandId: 26),
        const VehicleModel(id: 9, name: 'Azera', code: '9', brandId: 26),
        const VehicleModel(id: 10, name: 'Veloster', code: '10', brandId: 26),
      ],

      56: [ // Toyota - 8.24% MARKET SHARE
        const VehicleModel(id: 1, name: 'Hilux', code: '1', brandId: 56), // #19 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Corolla Cross', code: '2', brandId: 56), // #21 MAIS VENDIDO
        const VehicleModel(id: 3, name: 'Corolla', code: '3', brandId: 56), // #24 MAIS VENDIDO
        const VehicleModel(id: 4, name: 'Yaris', code: '4', brandId: 56),
        const VehicleModel(id: 5, name: 'RAV4', code: '5', brandId: 56),
        const VehicleModel(id: 6, name: 'SW4', code: '6', brandId: 56),
        const VehicleModel(id: 7, name: 'Camry', code: '7', brandId: 56),
        const VehicleModel(id: 8, name: 'Etios', code: '8', brandId: 56),
        const VehicleModel(id: 9, name: 'Prius', code: '9', brandId: 56),
        const VehicleModel(id: 10, name: 'Land Cruiser', code: '10', brandId: 56),
      ],

      14: [ // Jeep - 6.42% MARKET SHARE
        const VehicleModel(id: 1, name: 'Renegade', code: '1', brandId: 14), // #15 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Compass', code: '2', brandId: 14), // #18 MAIS VENDIDO
        const VehicleModel(id: 3, name: 'Commander', code: '3', brandId: 14),
        const VehicleModel(id: 4, name: 'Wrangler', code: '4', brandId: 14),
        const VehicleModel(id: 5, name: 'Grand Cherokee', code: '5', brandId: 14),
        const VehicleModel(id: 6, name: 'Cherokee', code: '6', brandId: 14),
      ],

      // === MARCAS CONSOLIDADAS ===

      22: [ // Ford
        const VehicleModel(id: 1, name: 'Ka', code: '1', brandId: 22),
        const VehicleModel(id: 2, name: 'Ka Sedan', code: '2', brandId: 22),
        const VehicleModel(id: 3, name: 'EcoSport', code: '3', brandId: 22),
        const VehicleModel(id: 4, name: 'Focus', code: '4', brandId: 22),
        const VehicleModel(id: 5, name: 'Fiesta', code: '5', brandId: 22),
        const VehicleModel(id: 6, name: 'Ranger', code: '6', brandId: 22),
        const VehicleModel(id: 7, name: 'Territory', code: '7', brandId: 22),
        const VehicleModel(id: 8, name: 'Mustang', code: '8', brandId: 22),
        const VehicleModel(id: 9, name: 'Edge', code: '9', brandId: 22),
        const VehicleModel(id: 10, name: 'Fusion', code: '10', brandId: 22),
      ],

      25: [ // Honda
        const VehicleModel(id: 1, name: 'HR-V', code: '1', brandId: 25), // #17 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Civic', code: '2', brandId: 25),
        const VehicleModel(id: 3, name: 'City', code: '3', brandId: 25),
        const VehicleModel(id: 4, name: 'Fit', code: '4', brandId: 25),
        const VehicleModel(id: 5, name: 'WR-V', code: '5', brandId: 25),
        const VehicleModel(id: 6, name: 'CR-V', code: '6', brandId: 25),
        const VehicleModel(id: 7, name: 'City Hatchback', code: '7', brandId: 25),
        const VehicleModel(id: 8, name: 'Civic Hatchback', code: '8', brandId: 25),
        const VehicleModel(id: 9, name: 'Accord', code: '9', brandId: 25),
        const VehicleModel(id: 10, name: 'Pilot', code: '10', brandId: 25),
      ],

      30: [ // Nissan
        const VehicleModel(id: 1, name: 'Kicks', code: '1', brandId: 30), // #10 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Versa', code: '2', brandId: 30),
        const VehicleModel(id: 3, name: 'March', code: '3', brandId: 30),
        const VehicleModel(id: 4, name: 'Sentra', code: '4', brandId: 30),
        const VehicleModel(id: 5, name: 'X-Trail', code: '5', brandId: 30),
        const VehicleModel(id: 6, name: 'Frontier', code: '6', brandId: 30),
        const VehicleModel(id: 7, name: 'Altima', code: '7', brandId: 30),
        const VehicleModel(id: 8, name: 'Pathfinder', code: '8', brandId: 30),
      ],

      36: [ // Renault  
        const VehicleModel(id: 1, name: 'Kwid', code: '1', brandId: 36), // #12 MAIS VENDIDO
        const VehicleModel(id: 2, name: 'Logan', code: '2', brandId: 36),
        const VehicleModel(id: 3, name: 'Sandero', code: '3', brandId: 36),
        const VehicleModel(id: 4, name: 'Duster', code: '4', brandId: 36),
        const VehicleModel(id: 5, name: 'Captur', code: '5', brandId: 36),
        const VehicleModel(id: 6, name: 'Fluence', code: '6', brandId: 36),
        const VehicleModel(id: 7, name: 'Master', code: '7', brandId: 36),
        const VehicleModel(id: 8, name: 'Oroch', code: '8', brandId: 36),
      ],

      // === MARCAS CHINESAS EM CRESCIMENTO ===

      238: [ // BYD - LÍDER CHINESA 3.1% MARKET SHARE
        const VehicleModel(id: 1, name: 'Song Plus', code: '1', brandId: 238),
        const VehicleModel(id: 2, name: 'Dolphin', code: '2', brandId: 238),
        const VehicleModel(id: 3, name: 'Yuan Plus', code: '3', brandId: 238),
        const VehicleModel(id: 4, name: 'Han', code: '4', brandId: 238),
        const VehicleModel(id: 5, name: 'Tang', code: '5', brandId: 238),
        const VehicleModel(id: 6, name: 'Seal', code: '6', brandId: 238),
        const VehicleModel(id: 7, name: 'Atto 3', code: '7', brandId: 238),
      ],

      300: [ // GWM - 13ª POSIÇÃO RANKING ANUAL
        const VehicleModel(id: 1, name: 'Haval H6', code: '1', brandId: 300),
        const VehicleModel(id: 2, name: 'Ora 03', code: '2', brandId: 300),
        const VehicleModel(id: 3, name: 'Poer', code: '3', brandId: 300),
        const VehicleModel(id: 4, name: 'Tank 300', code: '4', brandId: 300),
      ],

      245: [ // Caoa Chery
        const VehicleModel(id: 1, name: 'Tiggo 2', code: '1', brandId: 245),
        const VehicleModel(id: 2, name: 'Tiggo 3X', code: '2', brandId: 245),
        const VehicleModel(id: 3, name: 'Tiggo 5X', code: '3', brandId: 245),
        const VehicleModel(id: 4, name: 'Tiggo 7', code: '4', brandId: 245),
        const VehicleModel(id: 5, name: 'Tiggo 8', code: '5', brandId: 245),
        const VehicleModel(id: 6, name: 'Arrizo 6', code: '6', brandId: 245),
      ],

      13: [ // JAC
        const VehicleModel(id: 1, name: 'T40', code: '1', brandId: 13),
        const VehicleModel(id: 2, name: 'T50', code: '2', brandId: 13),
        const VehicleModel(id: 3, name: 'T60', code: '3', brandId: 13),
        const VehicleModel(id: 4, name: 'e-JS1', code: '4', brandId: 13),
        const VehicleModel(id: 5, name: 'e-JS4', code: '5', brandId: 13),
      ],

      // === MARCAS PREMIUM ===

      7: [ // BMW
        const VehicleModel(id: 1, name: 'X1', code: '1', brandId: 7),
        const VehicleModel(id: 2, name: 'X3', code: '2', brandId: 7),
        const VehicleModel(id: 3, name: 'X5', code: '3', brandId: 7),
        const VehicleModel(id: 4, name: '320i', code: '4', brandId: 7),
        const VehicleModel(id: 5, name: '116i', code: '5', brandId: 7),
        const VehicleModel(id: 6, name: 'i3', code: '6', brandId: 7),
      ],

      18: [ // Mercedes-Benz
        const VehicleModel(id: 1, name: 'Classe A', code: '1', brandId: 18),
        const VehicleModel(id: 2, name: 'Classe C', code: '2', brandId: 18),
        const VehicleModel(id: 3, name: 'GLA', code: '3', brandId: 18),
        const VehicleModel(id: 4, name: 'GLC', code: '4', brandId: 18),
        const VehicleModel(id: 5, name: 'Sprinter', code: '5', brandId: 18),
      ],

      6: [ // Audi
        const VehicleModel(id: 1, name: 'A3', code: '1', brandId: 6),
        const VehicleModel(id: 2, name: 'A4', code: '2', brandId: 6),
        const VehicleModel(id: 3, name: 'Q3', code: '3', brandId: 6),
        const VehicleModel(id: 4, name: 'Q5', code: '4', brandId: 6),
        const VehicleModel(id: 5, name: 'Q7', code: '5', brandId: 6),
      ],

      // === OUTRAS MARCAS IMPORTANTES ===

      27: [ // Kia
        const VehicleModel(id: 1, name: 'Sportage', code: '1', brandId: 27),
        const VehicleModel(id: 2, name: 'Cerato', code: '2', brandId: 27),
        const VehicleModel(id: 3, name: 'Picanto', code: '3', brandId: 27),
        const VehicleModel(id: 4, name: 'Sorento', code: '4', brandId: 27),
        const VehicleModel(id: 5, name: 'Soul', code: '5', brandId: 27),
      ],

      28: [ // Mitsubishi
        const VehicleModel(id: 1, name: 'L200', code: '1', brandId: 28),
        const VehicleModel(id: 2, name: 'ASX', code: '2', brandId: 28),
        const VehicleModel(id: 3, name: 'Outlander', code: '3', brandId: 28),
        const VehicleModel(id: 4, name: 'Eclipse Cross', code: '4', brandId: 28),
        const VehicleModel(id: 5, name: 'Pajero', code: '5', brandId: 28),
      ],

      34: [ // Peugeot
        const VehicleModel(id: 1, name: '208', code: '1', brandId: 34),
        const VehicleModel(id: 2, name: '2008', code: '2', brandId: 34),
        const VehicleModel(id: 3, name: '3008', code: '3', brandId: 34),
        const VehicleModel(id: 4, name: '307', code: '4', brandId: 34),
        const VehicleModel(id: 5, name: '408', code: '5', brandId: 34),
      ],

      15: [ // Citroën
        const VehicleModel(id: 1, name: 'C3', code: '1', brandId: 15),
        const VehicleModel(id: 2, name: 'C4 Cactus', code: '2', brandId: 15),
        const VehicleModel(id: 3, name: 'Aircross', code: '3', brandId: 15),
        const VehicleModel(id: 4, name: 'C4 Lounge', code: '4', brandId: 15),
        const VehicleModel(id: 5, name: 'Berlingo', code: '5', brandId: 15),
      ],

      24: [ // Land Rover
        const VehicleModel(id: 1, name: 'Evoque', code: '1', brandId: 24),
        const VehicleModel(id: 2, name: 'Discovery Sport', code: '2', brandId: 24),
        const VehicleModel(id: 3, name: 'Freelander', code: '3', brandId: 24),
        const VehicleModel(id: 4, name: 'Defender', code: '4', brandId: 24),
      ],

      48: [ // Volvo
        const VehicleModel(id: 1, name: 'XC40', code: '1', brandId: 48),
        const VehicleModel(id: 2, name: 'XC60', code: '2', brandId: 48),
        const VehicleModel(id: 3, name: 'XC90', code: '3', brandId: 48),
        const VehicleModel(id: 4, name: 'S60', code: '4', brandId: 48),
      ],

      49: [ // Tesla
        const VehicleModel(id: 1, name: 'Model 3', code: '1', brandId: 49),
        const VehicleModel(id: 2, name: 'Model Y', code: '2', brandId: 49),
        const VehicleModel(id: 3, name: 'Model S', code: '3', brandId: 49),
        const VehicleModel(id: 4, name: 'Model X', code: '4', brandId: 49),
      ],
    };

    return fallbackData[brandId] ?? [];
  }

  Future<void> clearCache() async {
    await _initPrefs();
    final keys = _prefs?.getKeys().where((key) => 
      key.startsWith(_brandsKey) || key.startsWith(_modelsKeyPrefix)
    ).toList() ?? [];
    
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }
}