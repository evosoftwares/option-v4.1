# Nova Lógica: Aprovação Baseada Apenas em Documentos

## 📋 Resumo da Mudança

**ANTES**: Motorista ficava online baseado em `working_hours` + `online_intent`
**AGORA**: Motorista fica online baseado APENAS em `documentos aprovados` + `online_intent`

### ❌ Removido Completamente
- Tabela `working_hours`
- Tabela `driver_schedules` 
- Tabela `driver_schedule_overrides`
- Campo `is_within_working_hours` da view `driver_effective_status`
- Toda lógica relacionada a horários de trabalho

### ✅ Nova Lógica
- Motorista só fica online se **TODOS** os documentos obrigatórios estão aprovados
- Não há mais restrições de horário - motorista controla quando quer trabalhar
- Foco total na validação de documentos

---

## 🏗️ Arquitetura da Nova Lógica

### Documentos Obrigatórios
Para um motorista ficar online, os seguintes documentos devem ter `status = 'approved'` e `is_current = true`:

1. **CNH_FRONT** - Frente da Carteira Nacional de Habilitação
2. **CNH_BACK** - Verso da Carteira Nacional de Habilitação  
3. **CRLV** - Certificado de Registro e Licenciamento do Veículo
4. **VEHICLE_FRONT** - Foto frontal do veículo

### Fórmula do Status Efetivo
```sql
effective_online = online_intent AND documents_validated

WHERE documents_validated = (
    CNH_FRONT.status = 'approved' AND CNH_FRONT.is_current = true AND
    CNH_BACK.status = 'approved' AND CNH_BACK.is_current = true AND
    CRLV.status = 'approved' AND CRLV.is_current = true AND
    VEHICLE_FRONT.status = 'approved' AND VEHICLE_FRONT.is_current = true
)
```

---

## 🗄️ Mudanças na Base de Dados

### View `driver_effective_status` (NOVA)
```sql
SELECT
    ds.driver_id,
    ds.online_intent,
    ds.updated_at as intent_updated_at,
    -- Verificar se TODOS os documentos obrigatórios estão aprovados
    (
        EXISTS (SELECT 1 FROM driver_documents WHERE driver_id = ds.driver_id 
                AND document_type = 'CNH_FRONT' AND status = 'approved' AND is_current = true)
        AND
        EXISTS (SELECT 1 FROM driver_documents WHERE driver_id = ds.driver_id 
                AND document_type = 'CNH_BACK' AND status = 'approved' AND is_current = true)
        AND
        EXISTS (SELECT 1 FROM driver_documents WHERE driver_id = ds.driver_id 
                AND document_type = 'CRLV' AND status = 'approved' AND is_current = true)
        AND
        EXISTS (SELECT 1 FROM driver_documents WHERE driver_id = ds.driver_id 
                AND document_type = 'VEHICLE_FRONT' AND status = 'approved' AND is_current = true)
    ) as documents_validated,
    -- Status efetivo: intenção online E documentos validados
    (ds.online_intent AND [mesma lógica acima]) as effective_online
FROM driver_status ds;
```

### Nova Função Auxiliar
```sql
CREATE FUNCTION check_driver_documents_approved(driver_uuid UUID) RETURNS BOOLEAN
-- Verifica se todos os documentos obrigatórios estão aprovados
```

### Trigger Automático
```sql
CREATE TRIGGER trigger_update_driver_status_on_document_approval
-- Atualiza automaticamente quando documentos são aprovados
```

---

## 🔧 Mudanças no Código Dart

### Modelo `DriverEffectiveStatus` (ATUALIZADO)
```dart
class DriverEffectiveStatus {
  final String driverId;
  final bool onlineIntent;
  final DateTime intentUpdatedAt;
  final bool documentsValidated; // NOVO campo
  final bool effectiveOnline;
  
  // ❌ REMOVIDO: isWithinWorkingHours
}
```

### Serviço `DriverStatusService` (ATUALIZADO)
```dart
// NOVO: Verifica documentos antes de permitir ficar online
Future<DriverStatus> setDriverOnline(String driverId) async {
  final documentsStatus = await checkRequiredDocumentsApproved(driverId);
  
  if (!documentsStatus['allApproved']) {
    throw DatabaseException('Não é possível ficar online. Documentos pendentes...');
  }
  
  return updateOnlineIntent(driverId, true);
}
```

---

## 🎯 Cenários de Uso

### ✅ Cenário 1: Motorista Aprovado
```
CNH_FRONT: approved ✅
CNH_BACK: approved ✅  
CRLV: approved ✅
VEHICLE_FRONT: approved ✅
online_intent: true ✅
→ effective_online: TRUE ✅ (Pode receber corridas)
```

### ❌ Cenário 2: Documentos Pendentes
```
CNH_FRONT: approved ✅
CNH_BACK: pending ⏳
CRLV: approved ✅
VEHICLE_FRONT: approved ✅
online_intent: true ✅
→ effective_online: FALSE ❌ (Não pode receber corridas)
```

### ❌ Cenário 3: Documento Rejeitado
```
CNH_FRONT: approved ✅
CNH_BACK: approved ✅
CRLV: rejected ❌
VEHICLE_FRONT: approved ✅
online_intent: true ✅
→ effective_online: FALSE ❌ (Precisa enviar CRLV novamente)
```

### ⏸️ Cenário 4: Motorista Offline por Escolha
```
CNH_FRONT: approved ✅
CNH_BACK: approved ✅
CRLV: approved ✅
VEHICLE_FRONT: approved ✅
online_intent: false ⏸️
→ effective_online: FALSE (Motorista escolheu ficar offline)
```

---

## 🚀 Como Aplicar as Mudanças

### 1. Executar Migração SQL
```bash
# Execute no Supabase
psql -f remove_working_hours_migration.sql
```

### 2. Atualizar Código Flutter
```bash
# Arquivos principais alterados:
lib/models/supabase/driver_effective_status_updated.dart
lib/services/driver_status_service_updated.dart
```

### 3. Remover Scripts Obsoletos
```bash
# Scripts removidos:
debug_working_hours.py
fix_working_hours_rls.py
fix_driver_effective_status_view.py
verify_fix.py
```

### 4. Validar Nova Lógica
```bash
python validate_documents_only_logic.py
```

---

## 📊 Benefícios da Nova Abordagem

### ✅ Simplicidade
- ❌ **ANTES**: `online_intent` + `horários` + `aprovação` + `documentos`
- ✅ **AGORA**: `online_intent` + `documentos` (apenas!)

### ✅ Flexibilidade para Motoristas
- Motoristas controlam quando querem trabalhar
- Não há mais restrições de horário
- Foco no que realmente importa: documentação válida

### ✅ Menos Bugs
- Menos lógica complexa = menos pontos de falha
- Não há mais problemas com fusos horários
- Não há mais confusão sobre horários de trabalho

### ✅ Experiência do Usuário
- Mensagens de erro mais claras sobre documentos
- Motoristas sabem exatamente o que fazer para ficar online
- Processo de aprovação mais transparente

---

## 🛠️ Troubleshooting

### Problema: "Não consigo ficar online"
**Solução**: Verificar status dos documentos
```sql
SELECT document_type, status, is_current 
FROM driver_documents 
WHERE driver_id = 'DRIVER_ID' 
AND document_type IN ('CNH_FRONT', 'CNH_BACK', 'CRLV', 'VEHICLE_FRONT');
```

### Problema: "effective_online sempre false"
**Verificações**:
1. `online_intent = true`?
2. Todos os 4 documentos têm `status = 'approved'`?
3. Todos os 4 documentos têm `is_current = true`?

### Problema: "View driver_effective_status não existe"
**Solução**: Execute a migração SQL primeiro
```sql
-- Verificar se view existe
SELECT table_name FROM information_schema.views 
WHERE table_name = 'driver_effective_status';
```

---

## 📈 Monitoramento

### Métricas Importantes
```sql
-- Motoristas com todos documentos aprovados
SELECT COUNT(*) FROM driver_effective_status WHERE documents_validated = true;

-- Motoristas efetivamente online
SELECT COUNT(*) FROM driver_effective_status WHERE effective_online = true;

-- Status de documentos por tipo
SELECT document_type, status, COUNT(*) 
FROM driver_documents 
WHERE is_current = true 
GROUP BY document_type, status;
```

### Dashboard Sugerido
- 📊 Total de motoristas cadastrados
- ✅ Motoristas com documentos aprovados
- 🟢 Motoristas efetivamente online
- ⏳ Documentos pendentes de aprovação
- ❌ Documentos rejeitados

---

## 🎉 Conclusão

A nova lógica remove a complexidade desnecessária dos horários de trabalho e foca no que realmente importa: **documentos aprovados**. 

Isso resulta em:
- **Código mais simples** e fácil de manter
- **Experiência melhor** para motoristas
- **Menos bugs** relacionados a horários
- **Processo de aprovação** mais claro e direto

### Documentos Obrigatórios Atualizados
- ✅ CNH_FRONT - Frente da carteira de motorista
- ✅ CNH_BACK - Verso da carteira de motorista
- ✅ CRLV - Certificado do veículo
- ✅ VEHICLE_FRONT - Foto frontal do veículo

### Status da Implementação
- ✅ Migração SQL criada
- ✅ Código Dart atualizado
- ✅ Scripts obsoletos removidos
- ✅ Documentação criada
- ✅ Script de validação disponível

**A nova lógica está pronta para ser testada e implementada! 🚀**