import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
    print('🔄 Inicializando Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase inicializado com sucesso!');
    
    // Verificar se Firebase Storage está disponível
    print('🔄 Verificando Firebase Storage...');
    final storage = FirebaseStorage.instance;
    print('✅ Firebase Storage disponível!');
    print('📦 Bucket: ${storage.bucket}');
    
    print('\n🎉 Teste básico do Firebase concluído com sucesso!');
    
  } catch (e, stackTrace) {
    print('❌ Erro no teste: $e');
    print('📍 Stack trace: $stackTrace');
  }
  
  // Executar app simples
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Test')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text('Firebase inicializado!', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Verifique o console para detalhes.'),
            ],
          ),
        ),
      ),
    );
  }
}