# Exemplo: Update de photo_url na tabela app_users

Este documento demonstra como implementar a atualização do campo `photo_url` na tabela `app_users` sem usar RLS (Row Level Security).

## 📋 Pré-requisitos

1. **Bucket configurado**: O bucket `user-photos` deve estar criado e configurado
2. **RLS desabilitado**: A tabela `app_users` deve ter RLS desabilitado
3. **Permissões básicas**: Usuários `anon` e `authenticated` devem ter permissões de UPDATE

## 🔧 Implementação no Flutter

### Método 1: Usando UserService.updateUser (Recomendado)

```dart
import '../services/user_service.dart';
import '../exceptions/app_exceptions.dart';

/// Atualiza a URL da foto do perfil do usuário
Future<bool> updateUserPhotoUrl(String userId, String newPhotoUrl) async {
  try {
    // Usar o método existente do UserService
    final updatedUser = await UserService.updateUser(
      userId: userId,
      photoUrl: newPhotoUrl,
    );
    
    print('✅ Photo URL atualizada com sucesso: ${updatedUser.photoUrl}');
    return true;
    
  } on UserNotFoundException catch (e) {
    print('❌ Usuário não encontrado: $e');
    return false;
    
  } on DatabaseException catch (e) {
    print('❌ Erro de banco de dados: ${e.message}');
    return false;
    
  } catch (e) {
    print('❌ Erro inesperado: $e');
    return false;
  }
}
```

### Método 2: Implementação direta com Supabase

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_helper.dart';

/// Atualiza diretamente a photo_url usando Supabase client
Future<bool> updatePhotoUrlDirect(String userId, String newPhotoUrl) async {
  try {
    final supabase = SupabaseHelper.client;
    if (supabase == null) {
      throw Exception('Supabase não inicializado');
    }

    final response = await supabase
        .from('app_users')
        .update({
          'photo_url': newPhotoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    print('✅ Photo URL atualizada: ${response['photo_url']}');
    return true;
    
  } on PostgrestException catch (e) {
    if (e.code == 'PGRST116') {
      print('❌ Usuário não encontrado: $userId');
    } else {
      print('❌ Erro PostgreSQL: ${e.message} (${e.code})');
    }
    return false;
    
  } catch (e) {
    print('❌ Erro inesperado: $e');
    return false;
  }
}
```

## 🎯 Exemplo de uso completo

```dart
/// Exemplo completo: Upload de foto + Update da URL
Future<void> uploadAndUpdateProfilePhoto(File imageFile, String userId) async {
  try {
    // 1. Upload da imagem para o bucket
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final uploadPath = 'profiles/$fileName';
    
    final supabase = SupabaseHelper.client!;
    await supabase.storage
        .from('user-photos')
        .upload(uploadPath, imageFile);
    
    // 2. Obter URL pública da imagem
    final publicUrl = supabase.storage
        .from('user-photos')
        .getPublicUrl(uploadPath);
    
    print('📸 Imagem enviada: $publicUrl');
    
    // 3. Atualizar photo_url no banco
    final success = await updateUserPhotoUrl(userId, publicUrl);
    
    if (success) {
      print('✅ Foto de perfil atualizada com sucesso!');
    } else {
      print('❌ Falha ao atualizar foto de perfil');
    }
    
  } catch (e) {
    print('❌ Erro no processo completo: $e');
  }
}
```

## 🔍 Verificação e Diagnóstico

### Script SQL para verificar configuração

```sql
-- Verificar se RLS está desabilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'app_users';

-- Verificar permissões
SELECT 
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'app_users'
AND privilege_type = 'UPDATE';

-- Verificar estrutura da coluna photo_url
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'app_users' 
AND column_name = 'photo_url';
```

### Script Python para teste

```python
import os
from supabase import create_client, Client

# Configuração (usar valores do app_config.dart)
url = "https://your-project.supabase.co"
key = "your-anon-key"

supabase: Client = create_client(url, key)

def test_photo_url_update(user_id: str, new_url: str):
    """Testa a atualização de photo_url"""
    try:
        result = supabase.table('app_users').update({
            'photo_url': new_url,
            'updated_at': 'now()'
        }).eq('id', user_id).execute()
        
        if result.data:
            print(f"✅ Update realizado: {result.data[0]['photo_url']}")
            return True
        else:
            print("❌ Nenhum registro atualizado")
            return False
            
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

# Exemplo de uso
# test_photo_url_update('user-uuid-here', 'https://example.com/photo.jpg')
```

## 🚨 Possíveis Problemas e Soluções

### 1. Erro: "missing UPDATE policy"

**Causa**: RLS ainda está habilitado ou faltam permissões

**Solução**:
```sql
-- Desabilitar RLS
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;

-- Garantir permissões
GRANT UPDATE ON app_users TO anon, authenticated;
```

### 2. Erro: "PGRST116" (No rows returned)

**Causa**: Usuário não existe ou ID incorreto

**Solução**: Verificar se o ID do usuário está correto

### 3. Erro: "column photo_url does not exist"

**Causa**: Coluna não existe na tabela

**Solução**:
```sql
-- Adicionar coluna se não existir
ALTER TABLE app_users 
ADD COLUMN IF NOT EXISTS photo_url TEXT;
```

## 📝 Notas Importantes

1. **Validação**: O `UserService.updateUser` já inclui validações básicas
2. **Timestamp**: O campo `updated_at` é automaticamente atualizado
3. **Segurança**: Sem RLS, a segurança deve ser gerenciada pela aplicação
4. **URLs**: Sempre usar URLs públicas válidas do Supabase Storage
5. **Logs**: Implementar logs adequados para debugging

## ✅ Checklist de Verificação

- [ ] Bucket `user-photos` criado e configurado
- [ ] RLS desabilitado na tabela `app_users`
- [ ] Permissões UPDATE concedidas para `anon` e `authenticated`
- [ ] Coluna `photo_url` existe na tabela
- [ ] UserService importado corretamente
- [ ] Tratamento de erros implementado
- [ ] Logs de debug configurados
- [ ] Teste realizado com sucesso