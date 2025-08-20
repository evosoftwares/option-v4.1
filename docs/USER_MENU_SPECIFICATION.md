# 📱 Especificação do Menu de Usuário - OPTION Mobilidade

**Data:** 2025-01-27  
**Versão:** 1.0  
**Baseado em:** `DB_TABLES_SUMMARY.md` e Material Design 3

## 🎯 Visão Geral

O menu de usuário é **adaptativo e contextual**, mudando dinamicamente baseado no tipo de usuário (passageiro/motorista) e status de aprovação. Segue os princípios do Material Design 3 e utiliza as cores definidas no `app_theme.dart`.

## 👥 Tipos de Menu

### 🚶 Menu do PASSAGEIRO

#### 📋 Seção Principal
```
┌─────────────────────────────────────┐
│ 👤 [Foto] João Silva               │
│     ⭐ 4.8 • 127 viagens           │
│     📱 +55 11 99999-9999           │
├─────────────────────────────────────┤
│ 🏠 Meu Perfil                      │
│ 📍 Locais Favoritos          [3]   │
│ 🕒 Histórico de Viagens            │
│ 💳 Pagamentos                      │
└─────────────────────────────────────┘
```

#### 🎁 Seção Promoções
```
┌─────────────────────────────────────┐
│ 🎟️ Promoções Ativas          [2]   │
│ 💰 Créditos e Cupons               │
└─────────────────────────────────────┘
```

#### ⚙️ Seção Configurações
```
┌─────────────────────────────────────┐
│ 🔔 Notificações              [5]   │
│ ⭐ Avaliar Motoristas              │
│ 🛡️ Segurança                       │
│ 🌐 Idioma e Região                 │
└─────────────────────────────────────┘
```

#### 🆘 Seção Suporte
```
┌─────────────────────────────────────┐
│ 💬 Central de Ajuda                │
│ 📞 Contato e Suporte               │
│ 📋 Reportar Problema               │
│ ℹ️ Sobre o App                     │
└─────────────────────────────────────┘
```

#### 🚪 Seção Conta
```
┌─────────────────────────────────────┐
│ 🔄 Trocar para Motorista           │
│ 🔐 Privacidade                     │
│ 📄 Termos de Uso                   │
│ 🚪 Sair da Conta                   │
└─────────────────────────────────────┘
```

---

### 🚗 Menu do MOTORISTA

#### 📋 Seção Principal
```
┌─────────────────────────────────────┐
│ 👤 [Foto] Maria Santos             │
│     ⭐ 4.9 • 342 viagens           │
│     🟢 ONLINE • Aprovado           │
│     📱 +55 11 88888-8888           │
├─────────────────────────────────────┤
│ 🏠 Meu Perfil                      │
│ 🚗 Meu Veículo                     │
│ 💰 Carteira                 R$ 245 │
│ 📊 Estatísticas                    │
└─────────────────────────────────────┘
```

#### 🛠️ Seção Operacional
```
┌─────────────────────────────────────┐
│ ⏰ Horários de Trabalho            │
│ 🗺️ Zonas de Atendimento            │
│ 🚫 Zonas Excluídas                 │
│ 💲 Preços Personalizados           │
│ 🕒 Histórico de Corridas           │
└─────────────────────────────────────┘
```

#### 📄 Seção Documentos
```
┌─────────────────────────────────────┐
│ 📋 Documentos Pessoais       ⚠️    │
│ 🚗 Documentos do Veículo     ✅    │
│ 📸 Fotos e Verificações      ✅    │
│ 🏦 Dados Bancários           ✅    │
└─────────────────────────────────────┘
```

#### ⚙️ Seção Configurações
```
┌─────────────────────────────────────┐
│ 🔔 Notificações              [3]   │
│ ⭐ Avaliar Passageiros             │
│ 🛡️ Segurança                       │
│ 🌐 Idioma e Região                 │
└─────────────────────────────────────┘
```

#### 🆘 Seção Suporte
```
┌─────────────────────────────────────┐
│ 💬 Central de Ajuda                │
│ 📞 Contato e Suporte               │
│ 📋 Reportar Problema               │
│ ℹ️ Sobre o App                     │
└─────────────────────────────────────┘
```

#### 🚪 Seção Conta
```
┌─────────────────────────────────────┐
│ 🔄 Trocar para Passageiro          │
│ 🔐 Privacidade                     │
│ 📄 Termos de Uso                   │
│ 🚪 Sair da Conta                   │
└─────────────────────────────────────┘
```

## 🎨 Design System

### 🎨 Cores (baseado em app_theme.dart)
```dart
// Cabeçalho do usuário
backgroundColor: Theme.of(context).colorScheme.primaryContainer
textColor: Theme.of(context).colorScheme.onPrimaryContainer

// Itens do menu
backgroundColor: Theme.of(context).colorScheme.surface
textColor: Theme.of(context).colorScheme.onSurface

// Itens com atenção (documentos pendentes)
backgroundColor: Theme.of(context).colorScheme.errorContainer
textColor: Theme.of(context).colorScheme.onErrorContainer

// Badges de notificação
backgroundColor: Theme.of(context).colorScheme.error
textColor: Theme.of(context).colorScheme.onError

// Status online/offline
onlineColor: Theme.of(context).colorScheme.tertiary
offlineColor: Theme.of(context).colorScheme.outline
```

### 📐 Espaçamento
```dart
// Padding padrão
horizontal: 16.0
vertical: 12.0

// Espaçamento entre seções
sectionSpacing: 24.0

// Altura dos itens
listTileHeight: 56.0
userHeaderHeight: 120.0
```

### 🔤 Tipografia
```dart
// Nome do usuário
style: Theme.of(context).textTheme.titleLarge

// Informações do usuário (rating, viagens)
style: Theme.of(context).textTheme.bodyMedium

// Títulos dos itens do menu
style: Theme.of(context).textTheme.bodyLarge

// Badges e contadores
style: Theme.of(context).textTheme.labelSmall
```

## 🔧 Implementação Técnica

### 📱 Estrutura do Widget
```dart
class UserMenuDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserHeader(),
          Expanded(
            child: ListView(
              children: [
                ...buildMenuSections(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 👤 Cabeçalho do Usuário
```dart
class UserHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    
    return Container(
      height: 120,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: user.photoUrl != null 
                  ? NetworkImage(user.photoUrl!) 
                  : null,
                child: user.photoUrl == null 
                  ? Icon(Icons.person) 
                  : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName ?? 'Usuário',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (user.userType == 'driver')
                      OnlineStatusIndicator(),
                    UserStatsRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 📋 Seções do Menu
```dart
List<Widget> buildMenuSections(BuildContext context) {
  final user = context.watch<UserProvider>().currentUser;
  
  if (user.userType == 'passenger') {
    return [
      MenuSection(
        title: 'Principal',
        items: [
          MenuTile(
            icon: Icons.person,
            title: 'Meu Perfil',
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          MenuTile(
            icon: Icons.location_on,
            title: 'Locais Favoritos',
            badge: savedPlacesCount,
            onTap: () => Navigator.pushNamed(context, '/saved_places'),
          ),
          // ... outros itens
        ],
      ),
      // ... outras seções
    ];
  } else {
    return [
      // Menu do motorista
    ];
  }
}
```

### 🏷️ Badges e Indicadores
```dart
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? badge;
  final VoidCallback onTap;
  final bool hasWarning;
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: hasWarning 
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(title),
      trailing: badge != null 
        ? Badge(
            label: Text('$badge'),
            backgroundColor: Theme.of(context).colorScheme.error,
          )
        : hasWarning
          ? Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            )
          : Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
```

## 🔄 Estados Dinâmicos

### 📊 Contadores e Badges
```dart
// Notificações não lidas
FutureBuilder<int>(
  future: NotificationService.getUnreadCount(),
  builder: (context, snapshot) {
    return MenuTile(
      badge: snapshot.data ?? 0,
      // ...
    );
  },
)

// Locais favoritos salvos
FutureBuilder<int>(
  future: SavedPlacesService.getCount(),
  builder: (context, snapshot) {
    return MenuTile(
      badge: snapshot.data ?? 0,
      // ...
    );
  },
)
```

### ⚠️ Status de Documentos (Motoristas)
```dart
FutureBuilder<DocumentStatus>(
  future: DriverDocumentService.getStatus(),
  builder: (context, snapshot) {
    final hasWarning = snapshot.data?.hasPendingDocuments ?? false;
    
    return MenuTile(
      title: 'Documentos Pessoais',
      hasWarning: hasWarning,
      // ...
    );
  },
)
```

### 🟢 Status Online/Offline
```dart
class OnlineStatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: DriverService.onlineStatusStream(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline 
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(width: 8),
            Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
```

## 📱 Navegação

### 🔄 Rotas do Menu
```dart
// routes.dart
Map<String, WidgetBuilder> menuRoutes = {
  // Passageiro
  '/profile': (context) => ProfileScreen(),
  '/saved_places': (context) => SavedPlacesScreen(),
  '/trip_history': (context) => TripHistoryScreen(),
  '/payments': (context) => PaymentsScreen(),
  '/promotions': (context) => PromotionsScreen(),
  
  // Motorista
  '/driver_profile': (context) => DriverProfileScreen(),
  '/vehicle': (context) => VehicleScreen(),
  '/wallet': (context) => DriverWalletScreen(),
  '/schedules': (context) => DriverSchedulesScreen(),
  '/operational_zones': (context) => OperationalZonesScreen(),
  '/documents': (context) => DriverDocumentsScreen(),
  
  // Comum
  '/notifications': (context) => NotificationsScreen(),
  '/ratings': (context) => RatingsScreen(),
  '/support': (context) => SupportScreen(),
  '/settings': (context) => SettingsScreen(),
  '/about': (context) => AboutScreen(),
};
```

### 🔐 Navegação Condicional
```dart
void navigateToProfile(BuildContext context) {
  final user = context.read<UserProvider>().currentUser;
  
  if (user.userType == 'driver') {
    Navigator.pushNamed(context, '/driver_profile');
  } else {
    Navigator.pushNamed(context, '/profile');
  }
}
```

## 🎯 Funcionalidades Especiais

### 🆘 Botão de Emergência
```dart
class EmergencyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => EmergencyService.triggerEmergency(),
        icon: Icon(Icons.emergency),
        label: Text('EMERGÊNCIA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          minimumSize: Size(double.infinity, 48),
        ),
      ),
    );
  }
}
```

### 💰 Saldo da Carteira (Motoristas)
```dart
class WalletBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: DriverWalletService.balanceStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        
        return MenuTile(
          icon: Icons.account_balance_wallet,
          title: 'Carteira',
          trailing: Text(
            'R\$ ${balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => Navigator.pushNamed(context, '/wallet'),
        );
      },
    );
  }
}
```

## 📊 Métricas e Analytics

### 📈 Estatísticas do Usuário
```dart
class UserStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    
    return FutureBuilder<UserStats>(
      future: UserStatsService.getStats(user.id),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        
        return Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            SizedBox(width: 4),
            Text(
              '${stats?.averageRating?.toStringAsFixed(1) ?? '0.0'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(width: 16),
            Text(
              '${stats?.totalTrips ?? 0} viagens',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}
```

## 🔧 Manutenibilidade

### 📝 Configuração por JSON
```dart
// menu_config.json
{
  "passenger_menu": {
    "sections": [
      {
        "title": "Principal",
        "items": [
          {
            "icon": "person",
            "title": "Meu Perfil",
            "route": "/profile",
            "badge_source": null
          }
        ]
      }
    ]
  },
  "driver_menu": {
    // ...
  }
}
```

### 🧪 Testes
```dart
// test/widgets/user_menu_test.dart
void main() {
  group('UserMenuDrawer', () {
    testWidgets('shows passenger menu for passenger user', (tester) async {
      // Arrange
      final mockUser = AppUser(
        userType: 'passenger',
        fullName: 'Test User',
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: UserMenuDrawer(),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Locais Favoritos'), findsOneWidget);
      expect(find.text('Carteira'), findsNothing);
    });
  });
}
```

---

## 🎯 Resumo dos Itens do Menu

### 🚶 **PASSAGEIRO (8 itens principais)**
1. **Meu Perfil** - Editar dados pessoais
2. **Locais Favoritos** - Casa, trabalho, outros
3. **Histórico de Viagens** - Viagens realizadas
4. **Pagamentos** - Métodos e histórico
5. **Promoções** - Cupons e créditos
6. **Notificações** - Mensagens do app
7. **Suporte** - Ajuda e contato
8. **Configurações** - Preferências gerais

### 🚗 **MOTORISTA (12 itens principais)**
1. **Meu Perfil** - Dados pessoais e aprovação
2. **Meu Veículo** - Informações do carro
3. **Carteira** - Saldo e transações
4. **Horários de Trabalho** - Disponibilidade
5. **Zonas de Atendimento** - Áreas de trabalho
6. **Documentos** - CNH, CRLV, fotos
7. **Histórico de Corridas** - Viagens realizadas
8. **Preços Personalizados** - Tarifas especiais
9. **Estatísticas** - Performance e métricas
10. **Notificações** - Mensagens do app
11. **Suporte** - Ajuda e contato
12. **Configurações** - Preferências gerais

O menu é **dinâmico, contextual e adaptativo**, proporcionando uma experiência personalizada para cada tipo de usuário! 🚀