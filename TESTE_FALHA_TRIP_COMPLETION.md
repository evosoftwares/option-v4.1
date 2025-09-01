# 🚨 Teste Falhando: Driver Trip Completion Flow

## 📋 Descrição
Teste de integração criado para documentar e validar o **fluxo completo** de conclusão de viagem do motorista, desde aceitar o pedido até finalizar com avaliação.

**Status**: ❌ **FALHANDO INTENCIONALMENTE** - documenta funcionalidades que precisam ser implementadas.

## 🎯 Localização do Teste
```
test/integration/driver_trip_completion_flow_test.dart
```

## 🔧 Como Executar
```bash
flutter test test/integration/driver_trip_completion_flow_test.dart
```

## ❌ Funcionalidades Testadas (que DEVEM falhar)

### 1. **Botões de Status na DriverTripScreen**
```dart
// ❌ ESTE TESTE DEVE FALHAR: Não existe botão "Cheguei ao local"
expect(find.text('Cheguei ao local'), findsOneWidget);

// ❌ ESTE TESTE DEVE FALHAR: Não existe botão "Passageiro embarcou"  
expect(find.text('Passageiro embarcou'), findsOneWidget);

// ❌ ESTE TESTE DEVE FALHAR: Não existe botão "Chegamos ao destino"
expect(find.text('Chegamos ao destino'), findsOneWidget);
```

### 2. **Tela de Avaliação Pós-Viagem**
```dart
// ❌ ESTE TESTE DEVE FALHAR: Não existe TripRatingScreen
expect(find.byType(TripRatingScreen), findsOneWidget);

// ❌ ESTE TESTE DEVE FALHAR: TripRatingScreen não existe
expect(find.text('Como foi sua experiência?'), findsOneWidget);
```

### 3. **Sistema de Cancelamento com Motivo**
```dart
// ❌ ESTE TESTE DEVE FALHAR: Não existe botão de cancelamento
expect(find.text('Cancelar viagem'), findsOneWidget);

// ❌ ESTE TESTE DEVE FALHAR: Não existe dialog de cancelamento
expect(find.text('Motivo do cancelamento'), findsOneWidget);
```

## 🏗️ Implementações Necessárias

### 1. **Melhorar DriverTripScreen**
**Arquivo**: `lib/screens/driver/driver_trip_screen.dart`

**Adicionar botões contextuais baseados no status da viagem**:

```dart
// Status: 'accepted' (motorista indo buscar)
FloatingActionButton(
  onPressed: _markDriverArrived,
  child: Text('Cheguei ao local'),
)

// Status: 'driver_arrived' (motorista chegou)  
FloatingActionButton(
  onPressed: _markPassengerPickedUp,
  child: Text('Passageiro embarcou'),
)

// Status: 'in_progress' (viagem em andamento)
FloatingActionButton(
  onPressed: _completeTrip,
  child: Text('Chegamos ao destino'),
)
```

### 2. **Criar TripRatingScreen**
**Arquivo**: `lib/screens/rating/trip_rating_screen.dart`

```dart
class TripRatingScreen extends StatefulWidget {
  const TripRatingScreen({
    required this.tripId,
    required this.isDriver, // true = motorista avalia passageiro
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Como foi sua experiência?'),
          // 5 estrelas para avaliação
          Row(
            children: List.generate(5, (i) => 
              IconButton(
                icon: Icon(Icons.star),
                onPressed: () => _setRating(i + 1),
              )
            ),
          ),
          ElevatedButton(
            onPressed: _submitRating,
            child: Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}
```

### 3. **Métodos de Atualização de Status**
**Arquivo**: `lib/services/trip_service.dart`

Já existem, mas precisam ser integrados na UI:
- ✅ `updateTripRequestStatus()` - existe
- ✅ `completeTrip()` - existe  
- ✅ `rateTrip()` - existe

### 4. **Navegação Automática**
**Arquivo**: `lib/main.dart`

```dart
'/trip_rating': (context) => TripRatingScreen.fromArgs(args),
```

## 📊 Fluxo Completo Testado

```
1. Motorista aceita pedido
   ↓
2. [DriverTripScreen] Botão "Cheguei ao local"
   ↓ 
3. Status: 'driver_arrived' → Botão "Passageiro embarcou"
   ↓
4. Status: 'in_progress' → Botão "Chegamos ao destino"  
   ↓
5. Status: 'completed' → Navega para TripRatingScreen
   ↓
6. Motorista avalia passageiro (1-5 estrelas)
   ↓
7. Volta para DriverHomeScreen
```

## 🎯 Critério de Sucesso

**O teste passará quando**:
1. ✅ Todos os botões de status existirem na `DriverTripScreen`
2. ✅ `TripRatingScreen` for criada e funcional
3. ✅ Navegação automática entre estados funcionar
4. ✅ Sistema de avaliação salvar no banco via `TripService.rateTrip()`
5. ✅ Histórico mostrar viagens completadas com avaliações

## 🚀 Execução

Este é um **teste red-green-refactor**:
1. ❌ **RED**: Teste falha (status atual)
2. ✅ **GREEN**: Implementar funcionalidades mínimas para passar
3. 🔄 **REFACTOR**: Melhorar implementação mantendo testes passando

**Benefício**: Garante que implementaremos **exatamente** o que o usuário precisa, nada mais, nada menos.