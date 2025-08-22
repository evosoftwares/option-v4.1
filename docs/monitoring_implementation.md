# Sistema de Monitoramento - Guia de Implementação

## Visão Geral

Este documento descreve a implementação completa do sistema de monitoramento para a aplicação Uber-like, incluindo logs estruturados, métricas, alertas, auditoria e observabilidade.

## Componentes Implementados

### 1. MonitoringService
**Localização:** `lib/services/monitoring_service.dart`

**Funcionalidades:**
- Logs estruturados com diferentes níveis (info, warning, error)
- Integração com Sentry para captura de erros
- Logs específicos para operações de zona
- Validação geográfica com logs
- Eventos de segurança
- Performance de queries de banco de dados
- Envio automático de logs para backend

**Uso:**
```dart
// Logs básicos
MonitoringService.logInfo('Operação iniciada');
MonitoringService.logWarning('Aviso importante');
MonitoringService.logError('Erro crítico');

// Logs específicos
MonitoringService.logZoneOperation(
  operation: 'CREATE',
  zoneId: 'zone_123',
  userId: 'user_456',
  duration: Duration(milliseconds: 150),
);
```

### 2. MetricsService
**Localização:** `lib/services/metrics_service.dart`

**Funcionalidades:**
- Contadores para eventos e operações
- Gauges para valores em tempo real
- Histogramas para distribuições de tempo
- Métricas específicas para APIs, banco de dados e validações
- Export em formato Prometheus e JSON
- Coleta automática de métricas do sistema

**Uso:**
```dart
// Métricas básicas
MetricsService.incrementCounter('api_requests', labels: {'endpoint': '/zones'});
MetricsService.setGauge('active_drivers', 150.0);
MetricsService.observeHistogram('response_time', 250.0);

// Métricas específicas
MetricsService.recordApiRequest('/api/zones', 200, Duration(milliseconds: 150));
MetricsService.recordDatabaseQuery('SELECT', Duration(milliseconds: 50));
```

### 3. AlertService
**Localização:** `lib/services/alert_service.dart`

**Funcionalidades:**
- Sistema de alertas com diferentes severidades
- Regras de alerta configuráveis
- Avaliação periódica de métricas
- Notificações via email, Slack, SMS e push
- Resolução automática e manual de alertas
- Integração com Supabase para persistência

**Tipos de Alerta:**
- `highLatency`: Latência alta em APIs
- `errorRate`: Taxa de erro elevada
- `securityBreach`: Violação de segurança
- `systemHealth`: Problemas de saúde do sistema
- `businessMetric`: Métricas de negócio críticas

**Uso:**
```dart
// Disparar alerta
AlertService.triggerAlert(
  type: AlertType.highLatency,
  severity: AlertSeverity.critical,
  title: 'Alta Latência Detectada',
  description: 'Tempo de resposta excedeu 2000ms',
);

// Consultar alertas
final activeAlerts = AlertService.getActiveAlerts();
final stats = AlertService.getAlertStatistics();
```

### 4. HealthCheckService
**Localização:** `lib/services/health_check_service.dart`

**Funcionalidades:**
- Verificação de saúde de APIs externas
- Monitoramento de Supabase, Google Maps, Gateway de Pagamento
- Status de saúde em tempo real
- Estatísticas de disponibilidade
- Configuração flexível de endpoints

**Uso:**
```dart
final healthService = HealthCheckService();

// Verificar saúde geral
final status = healthService.getOverallStatus();

// Adicionar verificação customizada
healthService.addHealthCheckConfig(
  HealthCheckConfig(
    serviceName: 'custom_api',
    endpoint: 'https://api.example.com/health',
    timeout: Duration(seconds: 5),
  ),
);
```

### 5. Dashboard de Monitoramento
**Localização:** `lib/screens/monitoring_dashboard_screen.dart`

**Funcionalidades:**
- Visualização em tempo real de métricas
- Gráficos de performance e disponibilidade
- Lista de alertas ativos
- Status de saúde dos serviços
- Interface responsiva e intuitiva

## Configuração do Backend

### Triggers de Auditoria (Supabase)
**Localização:** `supabase/audit_triggers.sql`

**Funcionalidades:**
- Auditoria automática de todas as operações CRUD
- Versionamento de dados
- Rastreamento de mudanças por usuário
- Compliance com regulamentações

### ELK Stack
**Localização:** `elk/`

**Componentes:**
- **Elasticsearch:** Armazenamento e indexação de logs
- **Logstash:** Pipeline de processamento de logs
- **Kibana:** Dashboards e visualizações

**Configurações:**
- Índices otimizados para diferentes tipos de log
- Pipelines de transformação de dados
- Dashboards pré-configurados
- Políticas de retenção de dados

## Configuração e Inicialização

### 1. Dependências
Adicione ao `pubspec.yaml`:
```yaml
dependencies:
  logger: ^2.0.2+1
  sentry_flutter: ^7.20.2
  http: ^1.1.0
  supabase_flutter: ^2.3.4

dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.9
```

### 2. Inicialização
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços de monitoramento
  await MonitoringService.initialize();
  await MetricsService.initialize();
  await AlertService.initialize();
  
  runApp(MyApp());
}
```

### 3. Configuração do Sentry
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
    options.environment = kDebugMode ? 'development' : 'production';
    options.tracesSampleRate = 1.0;
  },
  appRunner: () => runApp(MyApp()),
);
```

### 4. Configuração do Supabase
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

## Testes

### Executar Testes
```bash
flutter test test/services/monitoring_test.dart
```

### Cobertura de Testes
- ✅ MonitoringService: Inicialização, logs básicos
- ✅ MetricsService: Contadores, gauges, histogramas, export
- ✅ AlertService: Consulta de alertas, estatísticas, regras
- ✅ HealthCheckService: Status de saúde, configurações
- ✅ Testes de Integração: Cenários completos

## Métricas Principais

### Contadores
- `api_requests_total`: Total de requisições por endpoint
- `errors_total`: Total de erros por serviço
- `zone_operations_total`: Operações de zona por tipo
- `validation_failures_total`: Falhas de validação

### Gauges
- `active_drivers`: Número de motoristas ativos
- `active_zones`: Número de zonas ativas
- `memory_usage_bytes`: Uso de memória
- `cpu_usage_percent`: Uso de CPU

### Histogramas
- `api_response_time_ms`: Tempo de resposta das APIs
- `database_query_duration_ms`: Duração de queries
- `zone_operation_duration_ms`: Duração de operações de zona

## Alertas Configurados

### Regras Padrão
1. **Alta Latência:** API > 2000ms
2. **Taxa de Erro:** > 5% em 5 minutos
3. **Violação de Segurança:** Tentativas de acesso não autorizado
4. **Saúde do Sistema:** Serviços indisponíveis
5. **Métricas de Negócio:** KPIs críticos fora do normal

### Canais de Notificação
- **Email:** Alertas críticos e de aviso
- **Slack:** Notificações em tempo real
- **SMS:** Apenas alertas críticos
- **Push:** Notificações mobile para administradores

## Dashboards

### Kibana Dashboards
1. **Overview:** Visão geral do sistema
2. **API Performance:** Métricas de APIs
3. **Error Analysis:** Análise de erros
4. **Security Events:** Eventos de segurança
5. **Business Metrics:** KPIs de negócio

### Grafana Dashboards
1. **System Health:** Saúde dos serviços
2. **Performance Metrics:** Métricas de performance
3. **Alert Status:** Status dos alertas
4. **Resource Usage:** Uso de recursos

## Manutenção e Operação

### Logs
- **Localização:** Supabase + ELK Stack
- **Retenção:** 90 dias para logs operacionais, 1 ano para auditoria
- **Backup:** Backup diário automático

### Métricas
- **Coleta:** A cada 30 segundos
- **Agregação:** Minutely, hourly, daily
- **Retenção:** 1 ano de dados detalhados

### Alertas
- **Avaliação:** A cada 1 minuto
- **Escalação:** Automática após 15 minutos sem resolução
- **Cleanup:** Alertas resolvidos removidos após 30 dias

## Próximos Passos

### Recomendações para Produção

1. **Configuração de Ambiente:**
   - Configurar variáveis de ambiente para diferentes ambientes
   - Implementar rotação de logs
   - Configurar backup automático

2. **Segurança:**
   - Implementar autenticação para dashboards
   - Configurar HTTPS para todos os endpoints
   - Implementar rate limiting

3. **Performance:**
   - Otimizar queries de métricas
   - Implementar cache para dashboards
   - Configurar CDN para assets estáticos

4. **Escalabilidade:**
   - Implementar sharding para logs
   - Configurar cluster Elasticsearch
   - Implementar load balancing

5. **Compliance:**
   - Implementar GDPR compliance
   - Configurar auditoria de acesso
   - Implementar data masking

### Melhorias Futuras

1. **Machine Learning:**
   - Detecção de anomalias automática
   - Predição de falhas
   - Otimização automática de alertas

2. **Integração:**
   - Integração com ferramentas de CI/CD
   - Webhooks para sistemas externos
   - API para integração com terceiros

3. **Visualização:**
   - Dashboards mobile nativos
   - Realidade aumentada para visualização 3D
   - Mapas de calor em tempo real

## Suporte e Documentação

- **Documentação Técnica:** `/docs/`
- **Exemplos de Código:** `/examples/`
- **Troubleshooting:** `/docs/troubleshooting.md`
- **FAQ:** `/docs/faq.md`

---

**Versão:** 1.0.0  
**Data:** Janeiro 2025  
**Autor:** Sistema de Monitoramento Team