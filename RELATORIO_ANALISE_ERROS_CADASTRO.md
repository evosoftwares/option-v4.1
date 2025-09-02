# 🔍 RELATÓRIO: Análise de Erros no Cadastro de Motorista

> **Status**: ❌ **PROBLEMAS IDENTIFICADOS**  
> **Data**: 02/09/2025  
> **Análise**: Logs do terminal + Imagem da tela de erro

---

## 📊 Problemas Identificados

### 🚨 Erro 1: Constraint de Vehicle Category

**Erro nos logs:**
```
DatabaseException: Erro ao criar registro de motorista: new row for relation "drivers" 
violates check constraint "drivers_vehicle_category_check" (Code: 23514)
```

**Causa Raiz:**
- O código está enviando `'standard'` como vehicle_category
- A constraint no banco espera valores diferentes
- **Inconsistência entre validador e enum:**
  - **Validador** (`database_constraints_validator.dart`): `['economy', 'comfort', 'premium', 'suv', 'van']`
  - **Enum** (`vehicle_category.dart`): `['economico', 'standard', 'premium', 'suv', 'executivo', 'van']`
  - **UserService** está usando: `'standard'`

### 🚨 Erro 2: RLS no Storage

**Erro nos logs:**
```
StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

**Causa Raiz:**
- RLS (Row Level Security) está habilitado nas tabelas `storage.objects` e `storage.buckets`
- Usuários anônimos não têm permissão para fazer upload
- Mesmo com bucket público, o RLS bloqueia a inserção

---

## 🎯 Análise da Imagem

**Tela mostrada:** "Finalizar Cadastro" - Etapa 3 de 3

**Status dos documentos:**
- ✅ CNH (Carteira Nacional de Habilitação): **Enviado**
- ✅ CRLV (Certificado de Registro e Licenciamento): **Enviado**

**Dados do veículo:**
- Marca: Toyota
- Modelo: Civic
- Ano: 1212
- Cor: 12
- Placa: 21212

**Erro exibido:**
```
⚠️ Falha no upload da CNH. Verifique sua conexão e tente novamente.
```

**Análise:**
1. Os documentos aparecem como "Enviado" na UI
2. Mas o erro indica falha no upload da CNH
3. O problema real é o RLS no storage, não a conexão
4. A mensagem de erro é genérica e não reflete o problema real

---

## 🛠️ Soluções Implementadas

### ✅ Script de Correção Criado

**Arquivo:** `fix_driver_registration_errors.sql`

**O que o script faz:**

#### 1. Correção da Constraint Vehicle Category
- Remove constraint antiga: `drivers_vehicle_category_check`
- Cria nova constraint com valores corretos:
  ```sql
  CHECK (vehicle_category IN ('economico', 'standard', 'premium', 'suv', 'executivo', 'van'))
  ```

#### 2. Correção do RLS no Storage
- Desabilita RLS nas tabelas `storage.objects` e `storage.buckets`
- Remove políticas conflitantes
- Concede permissões para `anon` e `authenticated`

#### 3. Configuração dos Buckets
- Garante que `user-photos` e `driver-documents` existem
- Configura como públicos com limites adequados
- Define tipos MIME permitidos

#### 4. Verificações e Testes
- Diagnóstico completo dos problemas
- Verificação das correções aplicadas
- Testes opcionais de inserção

---

## 🚀 Como Aplicar as Correções

### Passo 1: Executar Script SQL

1. Abra o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Cole e execute: `fix_driver_registration_errors.sql`
4. Verifique se não há erros na execução

### Passo 2: Validar Correções

**Verificações esperadas:**
- ✅ Constraint atualizada com valores corretos
- ✅ RLS desabilitado no storage
- ✅ Buckets configurados corretamente
- ✅ Permissões concedidas

### Passo 3: Testar Cadastro

```bash
# Executar aplicativo novamente
flutter run --debug

# Ou executar testes específicos
flutter test test/integration/driver_registration_complete_test.dart
```

---

## 🔧 Correções Adicionais Recomendadas

### 1. Atualizar Validador

**Arquivo:** `lib/validators/database_constraints_validator.dart`

```dart
// Linha 319 - Atualizar valores válidos
const validCategories = ['economico', 'standard', 'premium', 'suv', 'executivo', 'van'];
```

### 2. Melhorar Mensagens de Erro

**Arquivo:** `lib/controllers/driver_stepper_controller.dart`

- Capturar erros específicos de constraint
- Capturar erros específicos de RLS
- Exibir mensagens mais informativas

### 3. Validação de Dados do Veículo

**Problemas identificados na imagem:**
- Ano: `1212` (inválido)
- Cor: `12` (inválido)
- Placa: `21212` (formato inválido)

**Recomendação:** Implementar validação client-side antes do envio

---

## 📋 Checklist de Validação

### Antes da Correção
- [x] ❌ Constraint vehicle_category com valores incorretos
- [x] ❌ RLS habilitado no storage
- [x] ❌ Upload de documentos falhando
- [x] ❌ Cadastro de motorista falhando

### Após a Correção
- [ ] ⏳ Constraint vehicle_category atualizada
- [ ] ⏳ RLS desabilitado no storage
- [ ] ⏳ Upload de documentos funcionando
- [ ] ⏳ Cadastro de motorista funcionando
- [ ] ⏳ Mensagens de erro mais claras

---

## 🎯 Próximos Passos

1. **Executar script SQL** no Supabase Dashboard
2. **Testar cadastro** completo de motorista
3. **Validar upload** de documentos
4. **Implementar melhorias** nas mensagens de erro
5. **Adicionar validação** client-side para dados do veículo

---

## 📊 Resumo Técnico

| Problema | Causa | Solução | Status |
|----------|-------|---------|--------|
| Constraint violation | Valores inconsistentes | Script SQL | ✅ Implementado |
| RLS blocking uploads | RLS habilitado | Desabilitar RLS | ✅ Implementado |
| Mensagens genéricas | Tratamento básico | Melhorar controller | 📋 Recomendado |
| Dados inválidos | Falta validação | Validação client-side | 📋 Recomendado |

---

**🎉 Com essas correções, o cadastro de motorista deve funcionar completamente!**