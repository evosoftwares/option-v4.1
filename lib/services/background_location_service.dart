import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de localização para motoristas
/// Atualiza a localização a cada 5 minutos automaticamente
/// Alinhado com a nova arquitetura baseada em driver_status e online_intent
class BackgroundLocationService {
  static const Duration _updateInterval = Duration(minutes: 5);
  
  static Timer? _locationTimer;
  static bool _isServiceRunning = false;
  
  /// Inicializa o serviço de localização
  static Future<void> initialize() async {
    try {
      print('🚀 BackgroundLocationService inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar BackgroundLocationService: $e');
    }
  }
  
  /// Inicia o monitoramento de localização para motoristas
  static Future<void> startLocationTracking() async {
    if (_isServiceRunning) {
      print('⚠️ Serviço de localização já está rodando');
      return;
    }
    
    try {
      // Verificar se é motorista autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('⚠️ Usuário não autenticado, não iniciando tracking');
        return;
      }
      
      // Verificar status do motorista no banco
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('driver_status, online_intent')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse == null) {
        print('⚠️ Usuário não é motorista, não iniciando tracking');
        return;
      }
      
      final driverStatus = driverResponse['driver_status'];
      final onlineIntent = driverResponse['online_intent'] ?? false;
      
      if (driverStatus != 'online' || !onlineIntent) {
        print('⚠️ Motorista não está online ou sem intenção online, não iniciando tracking');
        return;
      }
      
      // Verificar permissões de localização
      final permission = await _checkLocationPermission();
      if (!permission) {
        print('❌ Permissão de localização negada');
        return;
      }
      
      _isServiceRunning = true;
      
      // Iniciar timer para updates periódicos
      _startLocationUpdates();
      
      print('✅ Tracking de localização iniciado (a cada 5 minutos)');
    } catch (e) {
      print('❌ Erro ao iniciar tracking de localização: $e');
      _isServiceRunning = false;
    }
  }
  
  /// Para o monitoramento de localização
  static Future<void> stopLocationTracking() async {
    try {
      _isServiceRunning = false;
      
      // Cancelar timer
      _locationTimer?.cancel();
      _locationTimer = null;
      
      print('🛑 Tracking de localização parado');
    } catch (e) {
      print('❌ Erro ao parar tracking de localização: $e');
    }
  }
  
  /// Inicia updates de localização periódicos
  static void _startLocationUpdates() {
    _locationTimer = Timer.periodic(_updateInterval, (timer) async {
      await _updateDriverLocation();
    });
    
    // Primeira atualização imediata
    _updateDriverLocation();
  }
  
  /// Atualiza a localização do motorista no Supabase
  static Future<void> _updateDriverLocation() async {
    try {
      // Verificar se ainda é motorista online
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('⚠️ Usuário não autenticado, parando updates');
        await stopLocationTracking();
        return;
      }
      
      // Verificar status atual do motorista
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id, driver_status, online_intent')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse == null) {
        print('⚠️ Motorista não encontrado, parando updates');
        await stopLocationTracking();
        return;
      }
      
      final driverId = driverResponse['id'];
      final driverStatus = driverResponse['driver_status'];
      final onlineIntent = driverResponse['online_intent'] ?? false;
      
      if (driverStatus != 'online' || !onlineIntent) {
        print('⚠️ Motorista não está mais online, parando updates');
        await stopLocationTracking();
        return;
      }
      
      // Obter localização atual
      final position = await _getCurrentPosition();
      if (position == null) {
        print('❌ Não foi possível obter localização');
        return;
      }
      
      // Atualizar no Supabase
      final supabase = Supabase.instance.client;
      await supabase.from('drivers').update({
        'current_latitude': position.latitude,
        'current_longitude': position.longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      }).eq('id', driverId);
      
      print('📍 Localização atualizada: ${position.latitude}, ${position.longitude}');
      
      // Salvar última atualização localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_location_update', DateTime.now().toIso8601String());
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      
    } catch (e) {
      print('❌ Erro ao atualizar localização: $e');
    }
  }
  
  /// Obtém a posição atual do dispositivo
  static Future<Position?> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      return position;
    } catch (e) {
      print('❌ Erro ao obter posição: $e');
      return null;
    }
  }
  
  /// Verifica e solicita permissões de localização
  static Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('❌ Permissão de localização negada permanentemente');
        return false;
      }
      
      if (permission == LocationPermission.denied) {
        print('❌ Permissão de localização negada');
        return false;
      }
      
      // Verificar se o serviço de localização está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Serviço de localização desabilitado');
        return false;
      }
      
      return true;
    } catch (e) {
      print('❌ Erro ao verificar permissões: $e');
      return false;
    }
  }
  
  /// Verifica se o serviço está rodando
  static bool get isRunning => _isServiceRunning;
  
  /// Força uma atualização imediata de localização
  static Future<void> forceLocationUpdate() async {
    print('🔄 Forçando atualização de localização...');
    await _updateDriverLocation();
  }
}