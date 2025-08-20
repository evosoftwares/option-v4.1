# Instruções para Testar a Tela de Locais Favoritos

## 1. Configuração Inicial

### Adicionar a API Key do Google Maps
1. Abra o arquivo `.env`
2. Adicione sua chave de API:
   ```
   GOOGLE_MAPS_API_KEY=sua_chave_aqui
   ```

### Atualizar pubspec.yaml
Certifique-se de que as seguintes dependências estão incluídas:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  google_maps_flutter: ^2.5.0
  google_maps_webservice: ^0.0.20
  http: ^1.1.0
```

## 2. Executar o App

```bash
flutter pub get
flutter run
```

## 3. Fluxo de Teste

### Passo 1: Acesso ao Stepper
- Faça login ou registro
- Escolha o tipo de usuário
- Adicione seu telefone
- Na tela de foto de perfil, continue para a tela de locais

### Passo 2: Testar Funcionalidades

#### Adicionar Local
1. Toque no botão flutuante "+"
2. Preencha:
   - Nome: "Minha Casa"
   - Endereço: "Rua Principal, 123"
   - Tipo: "Casa"
3. Toque em "ADICIONAR"

#### Editar Local
1. Toque no ícone de lápis em um local
2. Altere as informações
3. Toque em "SALVAR"

#### Excluir Local
1. Toque no ícone de lixeira
2. Confirme a exclusão

#### Busca com Google Places (opcional)
1. Toque no botão "Buscar no mapa"
2. Use a interface de busca
3. Selecione um local

### Passo 3: Navegação
- **Voltar**: Retorna à tela anterior
- **Concluir**: Finaliza o registro e navega para a home

## 4. Testes de Validação

### Campos Obrigatórios
- Nome não pode estar vazio
- Endereço não pode estar vazio
- Tipo deve ser selecionado

### Limite de Locais
- Teste adicionar múltiplos locais
- Verifique a performance com 10+ locais

### Integração
- Verifique se os locais são salvos corretamente
- Confirme que aparecem na próxima sessão

## 5. Debug

### Problemas Comuns
1. **API Key inválida**: Verifique no console do Google Cloud
2. **Permissões de localização**: Ative no emulador/dispositivo
3. **Erro de rede**: Verifique conexão com internet

### Logs Úteis
```dart
// Adicione no StepperController
print('Locais salvos: ${favoriteLocations.length}');
```

## 6. Arquivos Criados/Modificados

- ✅ `lib/models/favorite_location.dart`
- ✅ `lib/controllers/stepper_controller.dart`
- ✅ `lib/screens/stepper/step3_locations_screen.dart`
- ✅ `lib/services/location_service.dart`

## 7. Próximos Passos

Após testar:
1. Integrar com backend para persistência
2. Adicionar geocoding para coordenadas
3. Implementar sugestões de rotas baseadas nos locais
4. Adicionar categorias personalizadas