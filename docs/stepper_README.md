# Stepper de Cadastro - Tela de Telefone

## Visão Geral
Implementação da primeira etapa do stepper de cadastro com validação de telefone brasileiro.

## Arquivos Criados
- `lib/controllers/stepper_controller.dart` - Controlador do stepper
- `lib/screens/stepper/step1_phone_screen.dart` - Tela de entrada de telefone
- `lib/screens/stepper/stepper_demo_screen.dart` - Tela de demonstração

## Funcionalidades Implementadas
- ✅ Máscara de telefone brasileiro: (##) # ####-####
- ✅ Validação de 11 dígitos (DDD + número)
- ✅ Tema via ColorScheme aplicado
- ✅ Botões Próximo e Voltar
- ✅ Integração com StepperController via Provider
- ✅ Validação em tempo real

## Como Testar

### Opção 1: Via Navegação
1. Execute o aplicativo normalmente
2. Adicione um botão em alguma tela existente para navegar para `/stepper_demo`
3. Ou altere a rota inicial no `main.dart` para `/stepper_demo`

### Opção 2: Via Código
```dart
// Em qualquer tela, use:
Navigator.pushNamed(context, '/stepper_demo');
```

### Valores de Teste Válidos
- (11) 9 1234-5678
- (21) 9 8765-4321
- (31) 9 1111-2222

### Valores de Teste Inválidos
- (11) 1234-5678 (falta o 9)
- 11 9 1234-5678 (falta os parênteses)
- (11) 9 123-4567 (falta dígitos)

## Observações
- A máscara é aplicada automaticamente durante a digitação
- O botão "Próximo" só é habilitado quando o telefone é válido
- O estado é mantido no StepperController usando Provider