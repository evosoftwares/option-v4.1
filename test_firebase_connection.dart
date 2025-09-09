import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  print('🔧 Testando conexão Firebase...');
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    print('✅ Firebase inicializado com sucesso!');
    
    // Testar Firebase Storage
    final storage = FirebaseStorage.instance;
    print('✅ Firebase Storage acessível');
    
    // Testar se consegue acessar o bucket
    final ref = storage.ref();
    print('✅ Storage reference criada');
    
    // Testar listagem (isso não requer upload)
    try {
      final listResult = await ref.listAll();
      print('✅ Consegue listar arquivos: ${listResult.items.length} items encontrados');
    } catch (e) {
      print('⚠️  Erro ao listar arquivos: $e');
    }
    
    print('🎉 Teste de conectividade Firebase concluído!');
    
  } catch (e) {
    print('❌ Erro no teste Firebase: $e');
  }
}