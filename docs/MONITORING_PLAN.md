# Plano Abrangente de Monitoramento - Sistema de Zonas de Operação

## Visão Geral

Este documento apresenta um plano completo para implementar monitoramento, logs e métricas para o sistema de zonas de operação do motorista em produção.

## 1. Sistema de Logs Estruturados

### 1.1 Categorias de Logs

#### Logs de Operações CRUD
- **Criação de zona**: Captura dados da nova zona, validações aplicadas
- **Atualização de zona**: Registra mudanças nos polígonos, multiplicadores
- **Exclusão de zona**: Log de remoção com motivo
- **Consultas**: Performance de queries espaciais

#### Logs de Validação
- **Validação geográfica**: Resultados da API externa
- **Normalização de dados**: Transformações aplicadas
- **Validação de limites**: Verificação de máximo de zonas por motorista

#### Logs de Segurança
- **Tentativas de acesso não autorizado**
- **Violações de RLS (Row Level Security)**
- **Operações administrativas**

#### Logs de Performance
- **Latência de operações**
- **Uso de recursos durante consultas espaciais**
- **Deadlocks e timeouts**

### 1.2 Estrutura Padrão dos Logs

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO|WARN|ERROR|DEBUG",
  "service": "zone_service",
  "operation": "create_zone|update_zone|delete_zone|validate_zone",
  "user_id": "uuid",
  "driver_id": "uuid",
  "zone_id": "uuid",
  "duration_ms": 150,
  "status": "success|error|warning",
  "metadata": {
    "zone_name": "Centro",
    "price_multiplier": 1.5,
    "coordinates_count": 4,
    "validation_errors": []
  },
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid coordinates",
    "stack_trace": "..."
  }
}
```

## 2. Métricas de Performance e Uso

### 2.1 Métricas de Latência
- **zone_operation_duration_seconds**: Tempo de resposta por operação
- **database_query_duration_seconds**: Tempo de queries no banco
- **external_api_duration_seconds**: Latência da API de validação geográfica

### 2.2 Métricas de Throughput
- **zone_operations_per_second**: Operações por segundo
- **concurrent_users**: Usuários simultâneos
- **api_requests_total**: Total de requisições por endpoint

### 2.3 Métricas de Erro
- **zone_operation_errors_total**: Erros por tipo de operação
- **validation_failures_total**: Falhas de validação
- **external_api_errors_total**: Erros da API externa

### 2.4 Métricas de Negócio
- **active_zones_total**: Total de zonas ativas
- **zones_per_driver**: Distribuição de zonas por motorista
- **average_price_multiplier**: Multiplicador médio por região
- **daily_zone_operations**: Operações diárias

### 2.5 Métricas de Recursos
- **cpu_usage_percent**: Uso de CPU
- **memory_usage_bytes**: Uso de memória
- **database_connections_active**: Conexões ativas no banco
- **disk_usage_percent**: Uso de disco

## 3. Sistema de Alertas

### 3.1 Alertas Críticos (P1)
- **Latência alta**: >2s para operações de zona
- **Taxa de erro elevada**: >5% em 5 minutos
- **API externa indisponível**: >3 falhas consecutivas
- **Banco de dados inacessível**: Falha de conexão

### 3.2 Alertas de Atenção (P2)
- **Uso de recursos alto**: CPU >80%, Memória >90%
- **Latência moderada**: >1s para operações
- **Taxa de erro moderada**: >2% em 10 minutos

### 3.3 Alertas de Negócio (P3)
- **Motorista excedendo limite**: >10 zonas por motorista
- **Multiplicadores extremos**: >5.0 ou <0.5
- **Zonas com coordenadas suspeitas**: Fora do Brasil

### 3.4 Alertas de Segurança (P1)
- **Tentativas de acesso não autorizado**: >5 em 1 minuto
- **Operações administrativas**: Qualquer operação de admin
- **Violações de RLS**: Tentativa de acesso a dados de outros usuários

## 4. Dashboard de Observabilidade

### 4.1 Painel Principal
- **Status de Saúde do Sistema**: Verde/Amarelo/Vermelho
- **Uptime**: Disponibilidade do serviço
- **Versão Atual**: Versão da aplicação em produção
- **Usuários Ativos**: Motoristas online

### 4.2 Painel de Performance
- **Gráfico de Latência**: Tempo de resposta em tempo real
- **Gráfico de Throughput**: Requisições por segundo
- **Gráfico de Erros**: Taxa de erro ao longo do tempo
- **Top Endpoints Lentos**: Operações mais demoradas

### 4.3 Painel de Negócio
- **Mapa de Calor**: Zonas ativas por região
- **Gráfico de Tendência**: Zonas criadas ao longo do tempo
- **Top Motoristas**: Por número de zonas
- **Distribuição de Multiplicadores**: Histograma de preços

### 4.4 Painel de Infraestrutura
- **Uso de Recursos**: CPU, Memória, Disco
- **Status de APIs Externas**: Disponibilidade
- **Conexões de Banco**: Pool de conexões
- **Logs em Tempo Real**: Stream de logs com filtros

## 5. Sistema de Auditoria

### 5.1 Tabela de Auditoria

```sql
CREATE TABLE driver_operation_zones_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    table_name TEXT NOT NULL DEFAULT 'driver_operation_zones',
    record_id UUID NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    client_ip INET,
    user_agent TEXT,
    session_id TEXT
);
```

### 5.2 Trigger de Auditoria

```sql
CREATE OR REPLACE FUNCTION audit_driver_operation_zones()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO driver_operation_zones_audit (
            operation_type, record_id, old_values, changed_by, client_ip
        ) VALUES (
            'DELETE', OLD.id, to_jsonb(OLD), auth.uid(), inet_client_addr()
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO driver_operation_zones_audit (
            operation_type, record_id, old_values, new_values, changed_by, client_ip
        ) VALUES (
            'UPDATE', NEW.id, to_jsonb(OLD), to_jsonb(NEW), auth.uid(), inet_client_addr()
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO driver_operation_zones_audit (
            operation_type, record_id, new_values, changed_by, client_ip
        ) VALUES (
            'INSERT', NEW.id, to_jsonb(NEW), auth.uid(), inet_client_addr()
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_driver_operation_zones
    AFTER INSERT OR UPDATE OR DELETE ON driver_operation_zones
    FOR EACH ROW EXECUTE FUNCTION audit_driver_operation_zones();
```

### 5.3 Retenção e Compliance
- **Retenção**: 2 anos para logs de auditoria
- **Criptografia**: Dados sensíveis criptografados
- **Backup**: Backup diário dos logs de auditoria
- **Acesso**: Log de quem acessa os dados de auditoria

## 6. Implementação Técnica

### 6.1 Flutter (Cliente)

#### Dependências
```yaml
dependencies:
  logger: ^2.0.1
  sentry_flutter: ^7.14.0
  dio_logging_interceptor: ^1.0.1
```

#### Configuração de Logs
```dart
class MonitoringService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void logZoneOperation({
    required String operation,
    required String userId,
    required String driverId,
    String? zoneId,
    Map<String, dynamic>? metadata,
    Duration? duration,
    String status = 'success',
    Object? error,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'zone_service',
      'operation': operation,
      'user_id': userId,
      'driver_id': driverId,
      'zone_id': zoneId,
      'duration_ms': duration?.inMilliseconds,
      'status': status,
      'metadata': metadata,
      if (error != null) 'error': error.toString(),
    };

    if (status == 'error') {
      _logger.e('Zone operation failed', logData);
      Sentry.captureException(error, extra: logData);
    } else {
      _logger.i('Zone operation completed', logData);
    }
  }
}
```

### 6.2 Supabase (Backend)

#### Health Check Function
```sql
CREATE OR REPLACE FUNCTION health_check()
RETURNS JSON AS $$
DECLARE
    result JSON;
    db_status TEXT;
    zones_count INTEGER;
BEGIN
    -- Verificar status do banco
    SELECT COUNT(*) INTO zones_count FROM driver_operation_zones;
    
    IF zones_count >= 0 THEN
        db_status := 'healthy';
    ELSE
        db_status := 'unhealthy';
    END IF;
    
    result := json_build_object(
        'status', 'ok',
        'timestamp', now(),
        'database', db_status,
        'total_zones', zones_count,
        'version', '1.0.0'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### 6.3 Prometheus Metrics

#### Configuração
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'uber-clone-zones'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s
```

#### Métricas Customizadas
```dart
class MetricsService {
  static final Counter zoneOperationsTotal = Counter(
    name: 'zone_operations_total',
    help: 'Total number of zone operations',
    labelNames: ['operation', 'status'],
  );

  static final Histogram zoneOperationDuration = Histogram(
    name: 'zone_operation_duration_seconds',
    help: 'Duration of zone operations',
    labelNames: ['operation'],
    buckets: [0.1, 0.5, 1.0, 2.0, 5.0],
  );

  static final Gauge activeZones = Gauge(
    name: 'active_zones_total',
    help: 'Total number of active zones',
  );

  static void recordZoneOperation(String operation, String status, Duration duration) {
    zoneOperationsTotal.labels([operation, status]).inc();
    zoneOperationDuration.labels([operation]).observe(duration.inMilliseconds / 1000.0);
  }
}
```

### 6.4 Grafana Dashboards

#### Dashboard Principal
```json
{
  "dashboard": {
    "title": "Uber Clone - Zone Operations",
    "panels": [
      {
        "title": "Zone Operations Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(zone_operations_total[5m])",
            "legendFormat": "{{operation}} - {{status}}"
          }
        ]
      },
      {
        "title": "Average Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(zone_operation_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

## 7. Cronograma de Implementação

### Fase 1: Fundação (Semanas 1-2)
- [ ] Implementar logs estruturados no Flutter
- [ ] Criar triggers de auditoria no Supabase
- [ ] Configurar Sentry para monitoramento de erros
- [ ] Implementar health check endpoints

### Fase 2: Métricas (Semanas 3-4)
- [ ] Configurar Prometheus para coleta de métricas
- [ ] Implementar métricas customizadas no código
- [ ] Configurar Grafana com dashboards básicos
- [ ] Criar alertas básicos no AlertManager

### Fase 3: Alertas (Semanas 5-6)
- [ ] Configurar alertas críticos
- [ ] Integrar notificações via Slack/email
- [ ] Implementar alertas de negócio
- [ ] Configurar alertas de segurança

### Fase 4: Dashboards Avançados (Semanas 7-8)
- [ ] Criar dashboards de negócio
- [ ] Implementar mapa de calor de zonas
- [ ] Configurar relatórios automatizados
- [ ] Implementar análise de tendências

### Fase 5: ELK e Finalização (Semanas 9-10)
- [ ] Configurar ELK Stack
- [ ] Migrar logs para Elasticsearch
- [ ] Criar dashboards no Kibana
- [ ] Testes finais e documentação

## 8. Próximos Passos

1. **Aprovação do Plano**: Revisar e aprovar o plano com stakeholders
2. **Setup de Ambiente**: Configurar ambiente de desenvolvimento
3. **Implementação Fase 1**: Começar com logs estruturados
4. **Testes Contínuos**: Validar cada fase antes de prosseguir
5. **Documentação**: Manter documentação atualizada
6. **Treinamento**: Treinar equipe para usar ferramentas de monitoramento

## 9. Considerações de Segurança

- **Dados Sensíveis**: Não logar informações pessoais em texto plano
- **Acesso Restrito**: Dashboards acessíveis apenas para equipe autorizada
- **Auditoria de Acesso**: Log de quem acessa dados de monitoramento
- **Criptografia**: Logs e métricas criptografados em trânsito e repouso
- **Retenção**: Política clara de retenção de dados

## 10. Custos Estimados

- **Grafana Cloud**: $50/mês para 10k métricas
- **Sentry**: $26/mês para 50k erros
- **ELK Stack**: $100/mês para 10GB/dia
- **Infraestrutura**: $200/mês para servidores de monitoramento
- **Total Estimado**: ~$376/mês

---

**Documento criado em**: Janeiro 2024  
**Versão**: 1.0  
**Responsável**: Equipe de Desenvolvimento  
**Próxima Revisão**: Março 2024