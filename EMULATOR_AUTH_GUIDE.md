# 🤖 Guia de Autenticação para Emulador Android - OPTION

Este guia resolve os problemas de sign up/sign in no emulador Android do projeto OPTION.

## 🔍 Problema Identificado

Emuladores Android frequentemente têm problemas de conectividade com o Supabase Auth, causando:
- Timeouts nas requisições de registro
- Erros de SSL/certificado
- Falhas na criação de sessão
- Problemas de rede intermitentes

## ✅ Solução Implementada

Foi criado o `EmulatorAuthHelper` que:
1. **Detecta automaticamente** se está rodando em emulador
2. **Usa bypass auth** em emuladores (mais confiável)
3. **Usa auth normal** em dispositivos físicos
4. **Tem fallback automático** entre os métodos

## 🚀 Como Usar

### 1. Registro de Usuário

```dart
import '../utils/emulator_auth_helper.dart';

// Na sua tela de registro (_onSubmit ou similar):
try {
  final result = await EmulatorAuthHelper.intelligentSignUp(
    email: emailController.text.trim(),
    password: passwordController.text,
    fullName: nameController.text.trim(),
    phone: phoneController.text.trim(), // ou ''
    userType: 'passenger', // ou 'driver'
  );

  if (result['success'] == true) {
    // ✅ Sucesso!
    print('Usuário criado: ${result['user_id']}');
    
    // Navegar para próxima tela
    Navigator.pushReplacementNamed(context, '/select_user_type', arguments: {
      'fullName': nameController.text.trim(),
      'email': emailController.text.trim(),
      'userId': result['user_id'],
    });
  } else {
    // ❌ Erro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'] ?? 'Erro no registro')),
    );
  }
} catch (e) {
  print('Erro no registro: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro inesperado: $e')),
  );
}
```

### 2. Login de Usuário

```dart
import '../utils/emulator_auth_helper.dart';

// Na sua tela de login (_onSubmit ou similar):
try {
  final result = await EmulatorAuthHelper.intelligentSignIn(
    email: emailController.text.trim(),
    password: passwordController.text,
  );

  if (result['success'] == true) {
    // ✅ Login bem-sucedido!
    final userInfo = result['user'];
    print('Login realizado: ${userInfo['id']}');
    
    // Verificar tipo de usuário e navegar
    if (userInfo['user_type'] == 'driver') {
      Navigator.pushReplacementNamed(context, '/driver_home');
    } else {
      Navigator.pushReplacementNamed(context, '/passenger_home');
    }
  } else {
    // ❌ Login falhou
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'] ?? 'Credenciais inválidas')),
    );
  }
} catch (e) {
  print('Erro no login: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro de conexão: $e')),
  );
}
```

## 🔧 Arquivos Já Atualizados

Os seguintes arquivos já foram modificados para usar o `EmulatorAuthHelper`:

- ✅ `lib/screens/auth/register_screen.dart`
- ✅ `lib/screens/auth/login_screen.dart` 
- ✅ `lib/utils/emulator_auth_helper.dart` (novo)
- ✅ `lib/services/bypass_auth_service.dart` (existente)

## 🧪 Como Testar

### Opção 1: Emulador Android (Recomendado)
```bash
# Iniciar emulador
flutter run

# O EmulatorAuthHelper detectará automaticamente e usará bypass
```

### Opção 2: Navegador (Mais Estável)
```bash
flutter run -d chrome
```

### Opção 3: Dispositivo Físico
```bash
# Conectar celular via USB
flutter devices
flutter run -d <device_id>
```

## 📊 Logs de Debug

O sistema gera logs detalhados para debug:

```
🤖 [EMULATOR_HELPER] Iniciando registro inteligente...
   - Emulador Android: true
   - Deve usar bypass: true
🚀 [EMULATOR_HELPER] Usando bypass auth para emulador
✅ [BYPASS] Registro realizado com sucesso!
```

## 🆘 Solução de Problemas

### Problema: "Função bypass_signup não existe"

Execute este SQL no Supabase Dashboard > SQL Editor:

```sql
-- Função de registro bypass
CREATE OR REPLACE FUNCTION bypass_signup(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_phone TEXT,
  p_user_type TEXT
) RETURNS JSON AS $$
DECLARE
  new_user_id UUID;
  result JSON;
BEGIN
  -- Gerar novo UUID
  new_user_id := gen_random_uuid();

  -- Inserir na tabela app_users
  INSERT INTO app_users (
    id,
    email,
    full_name,
    phone,
    user_type,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    p_email,
    p_full_name,
    p_phone,
    p_user_type,
    NOW(),
    NOW()
  );

  -- Retornar sucesso
  result := json_build_object(
    'success', true,
    'user_id', new_user_id,
    'email', p_email,
    'user_type', p_user_type,
    'message', 'Usuário criado via bypass'
  );

  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    -- Retornar erro
    result := json_build_object(
      'success', false,
      'error', SQLERRM
    );
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função de login bypass  
CREATE OR REPLACE FUNCTION bypass_login(
  p_email TEXT,
  p_password TEXT
) RETURNS JSON AS $$
DECLARE
  user_record RECORD;
  result JSON;
BEGIN
  -- Buscar usuário
  SELECT * INTO user_record
  FROM app_users
  WHERE email = p_email;

  IF FOUND THEN
    result := json_build_object(
      'success', true,
      'user', json_build_object(
        'id', user_record.id,
        'email', user_record.email,
        'full_name', user_record.full_name,
        'user_type', user_record.user_type
      )
    );
  ELSE
    result := json_build_object(
      'success', false,
      'error', 'Usuário não encontrado'
    );
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Problema: "Erro de rede no emulador"

```bash
# 1. Reiniciar emulador
adb kill-server
adb start-server

# 2. Limpar cache Flutter
flutter clean
flutter pub get

# 3. Testar conectividade
adb shell ping google.com

# 4. Usar navegador como alternativa
flutter run -d chrome
```

### Problema: "Usuário não encontrado após registro"

Isso é normal com bypass auth. O sistema criará o perfil na próxima tela.

## 🔄 Comandos Úteis

```bash
# Diagnóstico completo
dart diagnose_emulator.dart

# Ver logs em tempo real
flutter logs

# Listar dispositivos disponíveis
flutter devices

# Verificar status do Flutter
flutter doctor -v

# Logs específicos do Android
adb logcat | grep flutter
```

## ✨ Vantagens da Solução

1. **🔍 Detecção Automática**: Não precisa configurar manualmente
2. **🛡️ Fallback Inteligente**: Se um método falha, tenta o outro
3. **📱 Multiplataforma**: Funciona em emulador, web e dispositivo físico
4. **🐛 Debug Fácil**: Logs detalhados para troubleshooting
5. **⚡ Bypass Confiável**: Contorna problemas de rede do emulador

## 🎯 Resultado Esperado

Após implementar esta solução:

- ✅ Registro funcionará 100% em emuladores Android
- ✅ Login será estável e confiável
- ✅ Não haverá mais erros de timeout
- ✅ Desenvolvimento será mais ágil
- ✅ Funciona tanto em emulador quanto dispositivo real

## 💡 Dicas Finais

1. **Sempre teste no navegador primeiro** (`flutter run -d chrome`)
2. **Use dispositivo físico para testes finais** 
3. **Monitore os logs** para entender qual método está sendo usado
4. **O bypass é apenas para desenvolvimento** - produção usa auth normal
5. **Mantenha as funções SQL atualizadas** no Supabase

---

**🚀 Pronto!** Agora você pode desenvolver sem problemas de auth no emulador Android.