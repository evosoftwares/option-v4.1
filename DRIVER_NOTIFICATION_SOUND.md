# Som Personalizado para Notificações de Motoristas

Este documento descreve a implementação do sistema de som personalizado para notificações push direcionadas a motoristas.

## Funcionalidade

Quando um motorista recebe uma notificação push, o sistema reproduz automaticamente o arquivo de som `chegoucorridaOption.mp3` específico do projeto. Passageiros recebem notificações com o som padrão do sistema.

## Implementação

### 1. Arquivo de Som

- **Localização**: `assets/sounds/chegoucorridaOption.mp3`
- **Cópia para Android**: `android/app/src/main/res/raw/chegoucorridaoption.mp3`
- **Declaração no pubspec.yaml**: Incluído em `assets/sounds/`

### 2. Modificações no FCMService

#### Método `_isCurrentUserDriver()`
```dart
Future<bool> _isCurrentUserDriver() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    final driverResponse = await Supabase.instance.client
        .from('drivers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    
    return driverResponse != null;
  } catch (e) {
    _logger.e('Erro ao verificar se usuário é motorista', error: e);
    return false;
  }
}
```

#### Modificação no `_handleForegroundMessage()`
- Adicionada verificação se o usuário é motorista
- Passagem do parâmetro `isDriver` para o LocalNotificationService

### 3. Modificações no LocalNotificationService

#### Parâmetro `isDriver`
- Adicionado parâmetro opcional `bool isDriver = false` no método `showRideOfferNotification()`

#### Configuração de Som por Plataforma

**Android:**
```dart
final androidSound = isDriver ? 'chegoucorridaoption' : null;
sound: androidSound != null ? RawResourceAndroidNotificationSound(androidSound) : null,
```

**iOS:**
```dart
final iOSSound = isDriver ? 'chegoucorridaOption.mp3' : null;
sound: iOSSound,
```

## Configuração de Arquivos

### Android
1. Arquivo copiado para: `android/app/src/main/res/raw/chegoucorridaoption.mp3`
2. Nome do arquivo deve estar em minúsculas e sem caracteres especiais
3. Usado via `RawResourceAndroidNotificationSound`

### iOS
1. Arquivo incluído no bundle via `assets/sounds/`
2. Referenciado diretamente pelo nome: `chegoucorridaOption.mp3`
3. Configurado no `DarwinNotificationDetails`

## Fluxo de Funcionamento

1. **Recebimento da Notificação**: FCMService recebe notificação push
2. **Verificação de Usuário**: Sistema verifica se usuário atual é motorista consultando tabela `drivers`
3. **Configuração de Som**: LocalNotificationService configura som baseado no tipo de usuário
4. **Exibição**: Notificação é exibida com som personalizado (motorista) ou padrão (passageiro)

## Benefícios

- **Experiência Diferenciada**: Motoristas têm feedback sonoro específico para corridas
- **Identificação Rápida**: Som personalizado permite identificação imediata de notificações de trabalho
- **Flexibilidade**: Sistema pode ser facilmente expandido para outros tipos de usuários
- **Compatibilidade**: Funciona em Android e iOS

## Manutenção

### Alteração do Som
1. Substituir arquivo em `assets/sounds/chegoucorridaOption.mp3`
2. Copiar novo arquivo para `android/app/src/main/res/raw/`
3. Manter mesmo nome para compatibilidade

### Adição de Novos Tipos de Usuário
1. Expandir lógica de verificação no FCMService
2. Adicionar novos parâmetros no LocalNotificationService
3. Configurar sons específicos para cada tipo

## Testes

### Teste Manual
1. Fazer login como motorista
2. Enviar notificação push via painel administrativo
3. Verificar se som personalizado é reproduzido
4. Repetir teste com usuário passageiro
5. Confirmar que passageiro recebe som padrão

### Verificação de Arquivos
```bash
# Verificar arquivo de som existe
ls -la assets/sounds/chegoucorridaOption.mp3
ls -la android/app/src/main/res/raw/chegoucorridaoption.mp3

# Verificar declaração no pubspec.yaml
grep -A 5 "assets:" pubspec.yaml
```

## Troubleshooting

### Som não reproduz no Android
- Verificar se arquivo está em `android/app/src/main/res/raw/`
- Confirmar nome do arquivo em minúsculas
- Verificar permissões de notificação

### Som não reproduz no iOS
- Verificar se arquivo está incluído no bundle
- Confirmar configuração no `Info.plist`
- Verificar permissões de notificação

### Usuário não identificado como motorista
- Verificar dados na tabela `drivers`
- Confirmar autenticação do usuário
- Verificar logs de erro no console