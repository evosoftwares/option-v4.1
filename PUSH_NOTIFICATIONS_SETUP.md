# 🔔 Guia de Configuração - Sistema de Notificações Push

## 📋 Visão Geral

Este guia fornece instruções completas para configurar o sistema de notificações push no aplicativo Uber Clone, incluindo configurações para Android, iOS e Web.

## 🚀 Pré-requisitos

### Firebase Console
1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Crie um novo projeto ou use um existente
3. Ative o Firebase Cloud Messaging (FCM)
4. Configure as plataformas (Android, iOS, Web)

### Dependências Flutter
As seguintes dependências já estão configuradas no `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.2
```

## 🤖 Configuração Android

### 1. Arquivo de Configuração Firebase
- Baixe o arquivo `google-services.json` do Firebase Console
- Coloque em: `android/app/google-services.json`

### 2. Gradle Configuration
Adicione ao `android/build.gradle`:
```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

Adicione ao `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. Permissões e Configurações
O arquivo `AndroidManifest.xml` já está configurado com:
- ✅ Permissões FCM (WAKE_LOCK, VIBRATE, etc.)
- ✅ Serviços Firebase Messaging
- ✅ Metadados de configuração
- ✅ Ícone e canal de notificação padrão

### 4. Recursos Criados
- ✅ `res/values/colors.xml` - Cores para notificações
- ✅ `res/drawable/ic_notification.xml` - Ícone de notificação

## 🍎 Configuração iOS

### 1. Arquivo de Configuração Firebase
- Baixe o arquivo `GoogleService-Info.plist` do Firebase Console
- Adicione ao projeto iOS via Xcode

### 2. Capabilities no Xcode
Habilite as seguintes capabilities:
- ✅ Push Notifications
- ✅ Background Modes:
  - Remote notifications
  - Background fetch
  - Background processing

### 3. Certificados APNs
1. Gere certificados APNs no Apple Developer Portal
2. Faça upload no Firebase Console (Project Settings > Cloud Messaging)

### 4. Info.plist
O arquivo já está configurado com:
- ✅ Permissões de notificação
- ✅ Background modes
- ✅ Configurações Firebase
- ✅ Categorias de notificação personalizadas

## 🌐 Configuração Web

### 1. Configuração Firebase
- Registre seu app Web no Firebase Console
- Obtenha as configurações do Firebase
- Atualize `web/firebase-messaging-sw.js` com suas credenciais:

```javascript
const firebaseConfig = {
  apiKey: "sua-api-key",
  authDomain: "seu-projeto.firebaseapp.com",
  projectId: "seu-project-id",
  storageBucket: "seu-projeto.appspot.com",
  messagingSenderId: "seu-sender-id",
  appId: "seu-app-id"
};
```

### 2. Service Worker
O arquivo `firebase-messaging-sw.js` já está configurado com:
- ✅ Manipulação de mensagens em background
- ✅ Ações personalizadas de notificação
- ✅ Deep linking
- ✅ Analytics de interação

### 3. Manifest Web
Atualize `web/manifest.json` se necessário para PWA.

## 🔧 Configuração do Código Flutter

### 1. Inicialização
O sistema é inicializado automaticamente via `FCMService`:

```dart
// No main.dart
await FCMService.instance.initialize();
```

### 2. Gerenciamento de Tokens
```dart
// Obter token atual
String? token = await FCMService.instance.getToken();

// Registrar token no Supabase
await FCMService.instance.registerToken(userId);
```

### 3. Envio de Notificações
```dart
// Envio individual
await FCMService.instance.sendNotificationToToken(
  token: 'device_token',
  title: 'Título',
  body: 'Mensagem',
  data: {'key': 'value'},
);

// Envio em massa
await FCMService.instance.sendBulkNotification(
  tokens: ['token1', 'token2'],
  title: 'Título',
  body: 'Mensagem',
);
```

## 📊 Painel Administrativo

Acesse o painel em: `/admin/notifications`

### Funcionalidades:
- ✅ Envio de notificações personalizadas
- ✅ Segmentação de público
- ✅ Agendamento de notificações
- ✅ Templates reutilizáveis
- ✅ Analytics e histórico
- ✅ Gerenciamento de erros

## 🗄️ Estrutura do Banco de Dados

### Tabelas Supabase:

#### `fcm_tokens`
```sql
CREATE TABLE fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  token TEXT NOT NULL,
  platform TEXT NOT NULL,
  device_info JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### `notification_history`
```sql
CREATE TABLE notification_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  sent_at TIMESTAMP DEFAULT NOW(),
  campaign_id TEXT,
  audience_type TEXT,
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id)
);
```

#### `notification_recipients`
```sql
CREATE TABLE notification_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID REFERENCES notification_history(id),
  user_id UUID REFERENCES auth.users(id),
  token TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  delivered_at TIMESTAMP,
  opened_at TIMESTAMP,
  error_message TEXT
);
```

## 🔍 Testes e Debugging

### 1. Teste de Token
```dart
// Verificar se o token está sendo gerado
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### 2. Teste de Recebimento
```dart
// Listener para mensagens em foreground
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Mensagem recebida: ${message.notification?.title}');
});
```

### 3. Logs de Debug
- Android: `adb logcat | grep FCM`
- iOS: Console do Xcode
- Web: Console do navegador

## 🚨 Troubleshooting

### Problemas Comuns:

1. **Token não gerado**
   - Verificar configuração Firebase
   - Verificar permissões
   - Verificar conexão com internet

2. **Notificações não chegam**
   - Verificar token válido
   - Verificar configuração APNs (iOS)
   - Verificar service worker (Web)

3. **App em background não recebe**
   - Verificar background modes (iOS)
   - Verificar otimização de bateria (Android)

## 📱 Tipos de Notificação Suportados

### 1. Solicitação de Corrida
- Ações: Aceitar/Recusar
- Deep link para tela de corrida
- Som personalizado

### 2. Atualização de Corrida
- Status da corrida
- Localização do motorista
- ETA atualizado

### 3. Mensagem de Chat
- Ação de resposta rápida
- Deep link para conversa
- Badge count

### 4. Notificações do Sistema
- Promoções
- Atualizações do app
- Manutenção programada

## 🔐 Segurança

### Boas Práticas:
- ✅ Tokens criptografados no banco
- ✅ Validação de permissões
- ✅ Rate limiting para envios
- ✅ Logs de auditoria
- ✅ Sanitização de dados

## 📈 Analytics e Monitoramento

### Métricas Disponíveis:
- Taxa de entrega
- Taxa de abertura
- Interações por plataforma
- Performance por campanha
- Erros e falhas

### Dashboards:
- Painel administrativo interno
- Firebase Analytics
- Logs do Supabase

## 🔄 Manutenção

### Tarefas Regulares:
- Limpeza de tokens inativos
- Rotação de certificados
- Backup de dados de analytics
- Monitoramento de performance

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Consulte os logs de erro
2. Verifique a documentação do Firebase
3. Teste em ambiente de desenvolvimento
4. Contate a equipe de desenvolvimento

**Status**: ✅ Sistema Completo e Funcional
**Última Atualização**: Janeiro 2025