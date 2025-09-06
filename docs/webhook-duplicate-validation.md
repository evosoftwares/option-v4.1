# Tratamento de Duplicatas em Webhooks - Documentação

## Visão Geral

Esta documentação descreve a implementação de prevenção de duplicatas para webhooks do Asaas, garantindo que eventos não sejam processados múltiplas vezes.

## Problema Resolvido

O sistema não realizava validação de duplicatas para webhooks, o que poderia resultar no processamento repetido do mesmo evento de pagamento.

## Solução Implementada

### 1. Identificador Único
Utilizamos o campo `asaas_event_id` como chave única para identificar cada evento webhook do Asaas, conforme recomendado pela documentação oficial do Asaas.

### 2. Tabela de Rastreamento
Criada a tabela `asaas_webhook_events` para rastrear todos os webhooks processados:

```sql
CREATE TABLE asaas_webhook_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    asaas_event_id TEXT NOT NULL UNIQUE,
    event_type TEXT NOT NULL,
    payment_id TEXT NOT NULL,
    payload JSONB NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_asaas_webhook_events_event_id ON asaas_webhook_events(asaas_event_id);
CREATE INDEX idx_asaas_webhook_events_payment_id ON asaas_webhook_events(payment_id);
```

### 3. Serviço de Webhooks
Implementado o `WebhookService` que fornece:

- `isEventProcessed(eventId)`: Verifica se um evento já foi processado
- `recordProcessedEvent(...)`: Registra um evento como processado
- `getPaymentWebhookEvents(paymentId)`: Recupera todos os webhooks para um pagamento
- `cleanOldEvents(days)`: Remove eventos antigos para manutenção

### 4. Integração no Processamento

O método `processPaymentWebhook` no `PassengerPaymentService` foi atualizado para:

1. Extrair o `eventId` e `eventType` do payload
2. Verificar se o evento já foi processado usando `isEventProcessed`
3. Registrar o evento como processado antes de processar o pagamento
4. Continuar o processamento normal apenas se o evento for novo

## Fluxo de Processamento

```
Webhook Recebido → Verificar Duplicata → Registrar Evento → Processar Pagamento
```

## Exemplo de Uso

### Processamento de Webhook com Validação

```dart
// No seu endpoint de webhook
final paymentService = PassengerPaymentService();
await paymentService.processPaymentWebhook(webhookData);

// O serviço automaticamente:
// 1. Verifica se é duplicata
// 2. Registra o evento
// 3. Processa apenas se for novo
```

### Uso Direto do WebhookService

```dart
final webhookService = WebhookService(supabase);

// Verificar duplicata
final isDuplicate = await webhookService.isEventProcessed('evt_123456');

// Registrar evento manualmente
await webhookService.recordProcessedEvent(
  eventId: 'evt_123456',
  eventType: 'PAYMENT_RECEIVED',
  paymentId: 'pay_789',
  payload: webhookData,
);
```

## Testes

Foram criados testes automatizados para validar:
- Verificação de duplicatas
- Registro de eventos
- Tratamento de erros
- Integração com o serviço de pagamentos

Execute os testes:
```bash
flutter test test/services/webhook_service_test.dart
```

## Considerações de Segurança

1. **Idempotência**: Cada evento é processado apenas uma vez
2. **Transações**: Uso de transações quando aplicável
3. **Logs**: Todos os eventos são registrados para auditoria
4. **Índices**: Índices otimizados para consultas rápidas

## Manutenção

Para limpar eventos antigos (recomendado mensalmente):

```dart
await webhookService.cleanOldEvents(90); // Remove eventos com mais de 90 dias
```

## Suporte

Para questões relacionadas ao processamento de webhooks ou duplicatas, consulte:
- Documentação do Asaas sobre idempotência
- Logs de processamento em `asaas_webhook_events`
- Testes de integração no diretório `test/services/`