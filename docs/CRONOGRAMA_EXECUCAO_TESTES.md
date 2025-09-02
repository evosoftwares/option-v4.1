# Cronograma Detalhado de Execução - Correção de Testes

## Visão Geral do Projeto
**Objetivo**: Correção completa de todos os testes com conformidade ao arquivo `supabase.md`
**Duração Total**: 6 semanas
**Equipe**: Dev Team + QA Team + Tech Lead

---

## SEMANA 1: Análise e Planejamento

### Dias 1-3: FASE 1 - Análise Inicial

#### Dia 1: Mapeamento Completo dos Testes
**Responsável**: Dev Team
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-10:30** - Inventariar arquivos em `/test/unit/`, `/test/widget/`, `/test/integration_disabled/`
- [ ] **10:30-12:00** - Mapear dependências do Supabase por arquivo de teste
- [ ] **14:00-15:30** - Identificar testes que requerem conexão com banco
- [ ] **15:30-17:00** - Classificar testes por categoria e complexidade
- [ ] **17:00-18:00** - Documentar estrutura atual de mocks e helpers

**Entregáveis**:
- Planilha de inventário de testes
- Mapa de dependências Supabase
- Classificação por categoria

**Referência Supabase.md**:
- Verificar schema de `app_users`, `drivers`, `trips`
- Validar constraints e relacionamentos
- Identificar views e triggers utilizados

#### Dia 2: Análise de Dependências
**Responsável**: Dev Team
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-10:30** - Analisar imports e dependências do Supabase
- [ ] **10:30-12:00** - Verificar configurações de ambiente de teste
- [ ] **14:00-15:30** - Mapear serviços externos (OneSignal, Google Maps, etc.)
- [ ] **15:30-17:00** - Identificar plugins Flutter necessários
- [ ] **17:00-18:00** - Documentar gaps de configuração

**Entregáveis**:
- Diagrama de dependências
- Lista de configurações necessárias
- Identificação de serviços externos

#### Dia 3: FASE 2 - Identificação de Problemas
**Responsável**: Dev Team + QA Team
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-11:00** - Categorizar problemas por prioridade
- [ ] **11:00-12:00** - Analisar logs de falha detalhadamente
- [ ] **14:00-16:00** - Verificar conformidade com `supabase.md`
- [ ] **16:00-17:00** - Priorizar correções por impacto
- [ ] **17:00-18:00** - Criar matriz de riscos

**Entregáveis**:
- Categorização de problemas
- Análise de conformidade com supabase.md
- Matriz de priorização

---

## SEMANA 2: Correção de Configuração

### Dias 4-8: FASE 3.1 - Configuração Supabase

#### Dia 4: Criação do Helper Unificado
**Responsável**: Senior Dev
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-11:00** - Criar `SupabaseTestHelper` com inicialização
- [ ] **11:00-12:00** - Implementar cleanup adequado
- [ ] **14:00-16:00** - Criar mocks para cenários offline
- [ ] **16:00-17:00** - Validar contra schema supabase.md
- [ ] **17:00-18:00** - Testes unitários do helper

**Código Base**:
```dart
class SupabaseTestHelper {
  static bool _initialized = false;
  
  static Future<void> initializeForTesting() async {
    if (_initialized) return;
    
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _initialized = true;
  }
  
  static Future<void> cleanup() async {
    // Limpeza baseada em supabase.md
  }
}
```

#### Dia 5: Atualização de Testes Unitários
**Responsável**: Dev Team
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-10:30** - Adicionar `SupabaseTestHelper.initializeForTesting()` em `setUpAll`
- [ ] **10:30-12:00** - Implementar cleanup em `tearDownAll`
- [ ] **14:00-15:30** - Atualizar testes de autenticação
- [ ] **15:30-17:00** - Atualizar testes de serviços
- [ ] **17:00-18:00** - Validar execução dos testes corrigidos

#### Dia 6-7: Configuração Integration Test Plugin
**Responsável**: DevOps + Dev Team
**Duração**: 16 horas

**Tarefas Dia 6**:
- [ ] **09:00-12:00** - Mover testes de `test/integration_disabled/` para `integration_test/`
- [ ] **14:00-17:00** - Configurar `pubspec.yaml` com plugin
- [ ] **17:00-18:00** - Atualizar scripts de build

**Tarefas Dia 7**:
- [ ] **09:00-12:00** - Criar ambiente de teste isolado
- [ ] **14:00-17:00** - Configurar CI/CD para integration tests
- [ ] **17:00-18:00** - Testes de validação da configuração

#### Dia 8: Validação da Semana
**Responsável**: QA Team
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-12:00** - Executar todos os testes unitários
- [ ] **14:00-16:00** - Validar configuração de integration tests
- [ ] **16:00-17:00** - Documentar problemas encontrados
- [ ] **17:00-18:00** - Preparar relatório semanal

---

## SEMANA 3: Correção de Validadores

### Dias 9-13: FASE 3.2 - Validadores e Constraints

#### Dia 9: DatabaseConstraintsValidator
**Responsável**: Senior Dev
**Duração**: 8 horas

**Tarefas**:
- [ ] **09:00-11:00** - Revisar implementação de `validateAppUser`
- [ ] **11:00-12:00** - Analisar constraints em supabase.md
- [ ] **14:00-16:00** - Corrigir validações de UUID para lançar `ValidationException`
- [ ] **16:00-17:00** - Atualizar testes para comportamento correto
- [ ] **17:00-18:00** - Validar contra schema app_users

**Referência Supabase.md**:
```json
{
  "table_name": "app_users",
  "column_name": "id",
  "data_type": "uuid",
  "is_nullable": "NO"
}
```

#### Dia 10-11: UserDataValidator
**Responsável**: Dev Team
**Duração**: 16 horas

**Tarefas Dia 10**:
- [ ] **09:00-12:00** - Verificar conformidade com constraints de app_users
- [ ] **14:00-17:00** - Validar regras de negócio vs schema
- [ ] **17:00-18:00** - Atualizar testes de validação de telefone

**Tarefas Dia 11**:
- [ ] **09:00-12:00** - Implementar validações específicas por user_type
- [ ] **14:00-17:00** - Criar testes para novos cenários
- [ ] **17:00-18:00** - Validação completa dos validadores

#### Dia 12-13: PhoneValidator e Integrações
**Responsável**: Dev Team
**Duração**: 16 horas

**Tarefas**:
- [ ] Revisar PhoneValidator.validate
- [ ] Integrar com UserDataValidator.validatePhone
- [ ] Validar formatos brasileiros
- [ ] Testes de edge cases
- [ ] Documentar padrões aceitos

---

## SEMANA 4: Correção de UI e Widgets

### Dias 14-18: FASE 3.3 - Testes de Widget

#### Dia 14-15: Problemas de Layout
**Responsável**: Frontend Team
**Duração**: 16 horas

**Estratégias**:
- [ ] Aumentar tamanho da tela de teste para `Size(1200, 800)`
- [ ] Implementar scroll automático para elementos fora da tela
- [ ] Usar `warnIfMissed: false` onde apropriado
- [ ] Criar helper para interações complexas

#### Dia 16-17: Testes de Formulários
**Responsável**: Frontend Team
**Duração**: 16 horas

**Foco**:
- [ ] Revisar testes de RegisterScreen
- [ ] Implementar testes de validação em tempo real
- [ ] Validar campos obrigatórios vs schema app_users
- [ ] Testar fluxos de erro e sucesso

#### Dia 18: Validação de UI
**Responsável**: QA Team
**Duração**: 8 horas

**Tarefas**:
- [ ] Executar todos os testes de widget
- [ ] Validar interações complexas
- [ ] Documentar melhorias implementadas

---

## SEMANA 5: Testes de Integração

### Dias 19-23: FASE 3.4 - Testes de Integração

#### Dia 19-20: Ambiente de Teste
**Responsável**: DevOps + Backend Team
**Duração**: 16 horas

**Configuração**:
- [ ] Criar banco de dados de teste isolado
- [ ] Implementar seed data baseado em supabase.md
- [ ] Configurar cleanup automático entre testes
- [ ] Implementar mocks para serviços externos

#### Dia 21-23: Fluxos End-to-End
**Responsável**: Full Team
**Duração**: 24 horas

**Prioridades**:
1. **Autenticação**: Registro, login, logout
2. **Perfil**: Criação, edição, validação
3. **Viagens**: Solicitação, aceite, conclusão
4. **Pagamentos**: Processamento, validação

---

## SEMANA 6: Validação e Documentação

### Dias 24-28: FASE 4 e 5

#### Dia 24-25: FASE 4 - Validação Pós-Correção
**Responsável**: QA Team
**Duração**: 16 horas

**Execução Sistemática**:
- [ ] **Testes Unitários**: Meta 100% sucesso
- [ ] **Testes de Widget**: Meta 95% sucesso
- [ ] **Testes de Integração**: Meta 90% sucesso

**Validação de Conformidade**:
- [ ] Schema Compliance com supabase.md
- [ ] Business Rules Compliance
- [ ] Performance e Estabilidade

#### Dia 26-28: FASE 5 - Documentação
**Responsável**: Tech Lead + Dev Team
**Duração**: 24 horas

**Entregáveis**:
- [ ] `CHANGELOG_TESTES.md`
- [ ] `GUIA_TESTES.md`
- [ ] Procedimentos de CI/CD atualizados
- [ ] Diretrizes de manutenção
- [ ] Review completo e entrega

---

## Métricas de Acompanhamento

### Métricas Diárias
- Número de testes corrigidos
- Tempo médio de execução
- Taxa de sucesso por categoria
- Problemas identificados vs resolvidos

### Métricas Semanais
- Progresso geral do projeto (%)
- Conformidade com supabase.md (%)
- Cobertura de código (%)
- Riscos identificados e mitigados

### Métricas Finais
- **Quantitativos**:
  - 100% dos testes unitários passando
  - 95% dos testes de widget passando
  - 90% dos testes de integração passando
  - Tempo de execução total < 10 minutos

- **Qualitativos**:
  - Conformidade total com supabase.md
  - Cobertura de código > 80%
  - Documentação completa e atualizada
  - Processo de manutenção estabelecido

---

## Pontos de Controle

### Checkpoint 1 (Final Semana 1)
- ✅ Análise completa realizada
- ✅ Problemas categorizados
- ✅ Plano de correção aprovado

### Checkpoint 2 (Final Semana 2)
- ✅ Configuração Supabase corrigida
- ✅ Integration tests configurados
- ✅ Testes unitários funcionando

### Checkpoint 3 (Final Semana 3)
- ✅ Validadores corrigidos
- ✅ Conformidade com supabase.md
- ✅ Testes de validação passando

### Checkpoint 4 (Final Semana 4)
- ✅ Testes de widget funcionando
- ✅ Problemas de layout resolvidos
- ✅ Formulários validando corretamente

### Checkpoint 5 (Final Semana 5)
- ✅ Testes de integração funcionando
- ✅ Fluxos end-to-end validados
- ✅ Performance adequada

### Checkpoint Final (Final Semana 6)
- ✅ Todos os critérios de sucesso atendidos
- ✅ Documentação completa
- ✅ Processo de manutenção estabelecido
- ✅ Equipe treinada

---

## Recursos Necessários

### Humanos
- **Senior Dev**: 2 pessoas (40h/semana)
- **Dev Team**: 4 pessoas (40h/semana)
- **QA Team**: 2 pessoas (40h/semana)
- **DevOps**: 1 pessoa (20h/semana)
- **Tech Lead**: 1 pessoa (10h/semana)

### Técnicos
- Ambiente de desenvolvimento isolado
- Banco de dados de teste
- Acesso a serviços externos para mocks
- Ferramentas de CI/CD
- Documentação atualizada do supabase.md

### Ferramentas
- Flutter Test Framework
- Integration Test Plugin
- Supabase Test Environment
- Mocking Libraries
- Coverage Tools

---

*Este cronograma será ajustado conforme necessário durante a execução, mantendo sempre a referência ao arquivo supabase.md como base para todas as validações.*