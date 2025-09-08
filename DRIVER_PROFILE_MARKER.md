# Ícone de Perfil do Motorista no Mapa

## Descrição

Esta implementação substitui o ícone padrão (quadrado preto) do motorista no Google Maps pela foto de perfil do motorista redimensionada para 60x60 pixels em formato circular.

## Implementação

### Arquivo Modificado
- `lib/screens/passenger/passenger_trip_screen.dart`

### Principais Mudanças

1. **Novo Campo de Estado**
   ```dart
   app_user.User? _driverUser;
   ```
   Armazena os dados do usuário do motorista (incluindo a foto de perfil).

2. **Carregamento dos Dados do Usuário**
   ```dart
   Future<void> _loadDriverUserData() async {
     if (_currentDriver == null) return;

     try {
       final user = await UserService.getUserById(_currentDriver!.userId);
       if (user != null && user.photoUrl != null) {
         setState(() {
           _driverUser = user;
         });
         await _createDriverProfileMarker();
       }
     } catch (e) {
       debugPrint('Erro ao carregar dados do usuário do motorista: $e');
     }
   }
   ```

3. **Criação do Marcador Circular**
   ```dart
   Future<BitmapDescriptor> _createCircularMarkerFromUrl(String imageUrl, int size) async
   ```
   - Baixa a imagem da foto de perfil
   - Cria um canvas circular de 60x60 pixels
   - Desenha a foto redimensionada dentro do círculo
   - Adiciona bordas branca e cinza para contraste
   - Converte para BitmapDescriptor para uso no Google Maps

### Fluxo de Funcionamento

1. **Carregamento Inicial**: Quando o motorista é carregado, chama `_loadDriverUserData()`
2. **Busca do Usuário**: Usa `UserService.getUserById()` para obter dados completos do motorista
3. **Verificação da Foto**: Se existe `photoUrl`, cria o marcador personalizado
4. **Criação do Ícone**: Processa a imagem em um marcador circular
5. **Atualização do Mapa**: Substitui o ícone padrão pelo personalizado

### Tratamento de Erros

- **Timeout**: 10 segundos para carregar a imagem
- **URL Inválida**: Verifica se a URL não está vazia
- **Fallback**: Usa o ícone de carro padrão em caso de erro
- **Logging**: Registra erros para debug

### Características Visuais

- **Tamanho**: 60x60 pixels
- **Formato**: Circular com clipping
- **Bordas**: 
  - Borda branca interna (3px)
  - Borda cinza externa (1px) para contraste
- **Fundo**: Branco para casos de transparência

### Dependências Adicionadas

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../models/user.dart' as app_user;
import '../../services/user_service.dart';
```

### Integração com Modelo de Dados

A implementação usa:
- `Driver.userId` para encontrar o usuário correspondente
- `User.photoUrl` para obter a URL da foto de perfil
- `UserService.getUserById()` para buscar dados do usuário

### Performance

- Cache da foto processada enquanto a tela estiver ativa
- Timeout configurado para evitar travamentos
- Fallback rápido para ícone padrão em caso de erro
- Processamento assíncrono para não bloquear a UI

### Compatibilidade

- Funciona com qualquer formato de imagem suportado pelo NetworkImage
- Compatível com URLs de Storage do Supabase/Firebase
- Mantém compatibilidade com implementação anterior (fallback)

## Como Testar

1. Certifique-se de que um motorista tenha foto de perfil cadastrada
2. Inicie uma viagem como passageiro
3. Observe o mapa - o ícone do motorista deve aparecer como a foto de perfil circular
4. Em caso de erro/sem foto, deve aparecer o ícone de carro padrão

## Benefícios

- **UX Melhorada**: Passageiros podem identificar visualmente o motorista
- **Personalização**: Cada motorista tem seu ícone único
- **Profissional**: Remove o quadrado preto genérico
- **Confiança**: Facilita o reconhecimento do motorista correto