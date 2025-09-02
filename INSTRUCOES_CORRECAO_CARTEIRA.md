# Instruções para Correção do Problema da Carteira

## Problema Identificado
Usuários com `user_type='driver'` não possuem registros correspondentes na tabela `drivers`, causando o erro "Perfil de motorista não encontrado" ao acessar a carteira.

## Solução Implementada

### 1. Correção Temporária no Código Flutter ✅
- Modificada a `WalletService` para criar automaticamente registros de motorista quando necessário
- Melhorada a interface de usuário para mostrar mensagem mais amigável
- Implementado fallback automático para criação de registros

### 2. Correção Definitiva no Banco de Dados (PENDENTE)

#### Passo 1: Acesse o Supabase
1. Faça login no [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecione seu projeto
3. Vá para "SQL Editor" no menu lateral

#### Passo 2: Execute o Script de Correção
Copie e cole o seguinte script SQL:

```sql
-- Função para criar registros de motorista automaticamente
CREATE OR REPLACE FUNCTION auto_create_driver_record()
RETURNS TRIGGER AS $$
BEGIN
  -- Verifica se o user_type foi alterado para 'driver'
  IF NEW.user_type = 'driver' AND (OLD.user_type IS NULL OR OLD.user_type != 'driver') THEN
    -- Verifica se já existe um registro na tabela drivers
    IF NOT EXISTS (SELECT 1 FROM drivers WHERE user_id = NEW.id) THEN
      -- Cria um novo registro de motorista com valores padrão
      INSERT INTO drivers (
        user_id,
        cnh_number,
        cnh_expiry_date,
        cnh_photo_url,
        vehicle_brand,
        vehicle_model,
        vehicle_year,
        vehicle_color,
        vehicle_plate,
        vehicle_category,
        crlv_photo_url,
        approval_status,
        approved_by,
        approved_at,
        is_online,
        accepts_pet,
        pet_fee,
        accepts_grocery,
        grocery_fee,
        accepts_condo,
        condo_fee,
        stop_fee,
        ac_policy,
        custom_price_per_km,
        custom_price_per_minute,
        bank_account_type,
        bank_code,
        bank_agency,
        bank_account,
        pix_key,
        pix_key_type,
        consecutive_cancellations,
        total_trips,
        average_rating,
        current_latitude,
        current_longitude,
        last_location_update
      ) VALUES (
        NEW.id,
        'PENDENTE_CADASTRO',
        CURRENT_DATE + INTERVAL '1 year',
        '',
        'PENDENTE',
        'PENDENTE',
        2020,
        'PENDENTE',
        'PENDENTE',
        'standard',
        '',
        'pending',
        NULL,
        NULL,
        false,
        false,
        0.0,
        false,
        0.0,
        false,
        0.0,
        0.0,
        'on_request',
        0.0,
        0.0,
        NULL,
        NULL,
        NULL,
        NULL,
        '',
        'email',
        0,
        0,
        NULL,
        NULL,
        NULL,
        NULL
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cria o trigger para executar a função automaticamente
DROP TRIGGER IF EXISTS auto_create_driver_record_trigger ON app_users;
CREATE TRIGGER auto_create_driver_record_trigger
  AFTER UPDATE OF user_type ON app_users
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_driver_record();

-- Corrige registros existentes (usuários que já são drivers mas não têm registro)
INSERT INTO drivers (
  user_id,
  cnh_number,
  cnh_expiry_date,
  cnh_photo_url,
  vehicle_brand,
  vehicle_model,
  vehicle_year,
  vehicle_color,
  vehicle_plate,
  vehicle_category,
  crlv_photo_url,
  approval_status,
  approved_by,
  approved_at,
  is_online,
  accepts_pet,
  pet_fee,
  accepts_grocery,
  grocery_fee,
  accepts_condo,
  condo_fee,
  stop_fee,
  ac_policy,
  custom_price_per_km,
  custom_price_per_minute,
  bank_account_type,
  bank_code,
  bank_agency,
  bank_account,
  pix_key,
  pix_key_type,
  consecutive_cancellations,
  total_trips,
  average_rating,
  current_latitude,
  current_longitude,
  last_location_update
)
SELECT 
  u.id,
  'PENDENTE_CADASTRO',
  CURRENT_DATE + INTERVAL '1 year',
  '',
  'PENDENTE',
  'PENDENTE',
  2020,
  'PENDENTE',
  'PENDENTE',
  'standard',
  '',
  'pending',
  NULL,
  NULL,
  false,
  false,
  0.0,
  false,
  0.0,
  false,
  0.0,
  0.0,
  'on_request',
  0.0,
  0.0,
  NULL,
  NULL,
  NULL,
  NULL,
  '',
  'email',
  0,
  0,
  NULL,
  NULL,
  NULL,
  NULL
FROM app_users u
WHERE u.user_type = 'driver'
  AND NOT EXISTS (SELECT 1 FROM drivers d WHERE d.user_id = u.id);
```

#### Passo 3: Verificar a Correção
Execute esta consulta para verificar se a correção funcionou:

```sql
-- Verificar usuários drivers sem registro na tabela drivers
SELECT 
  u.id,
  u.email,
  u.full_name,
  u.user_type,
  CASE WHEN d.id IS NULL THEN 'SEM REGISTRO' ELSE 'COM REGISTRO' END as status_driver
FROM app_users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.user_type = 'driver'
ORDER BY status_driver, u.email;
```

## Resultado Esperado

### Antes da Correção
- Usuários com `user_type='driver'` viam erro "Perfil de motorista não encontrado"
- Impossibilidade de acessar a carteira

### Após a Correção
- Todos os usuários drivers terão registros na tabela `drivers`
- Acesso normal à carteira
- Criação automática de registros para novos drivers
- Interface mais amigável durante o processo

## Monitoramento

Após executar o script, monitore os logs do aplicativo para verificar:
- Mensagens de criação automática de registros: `🔧 Criando registro de motorista automaticamente`
- Sucessos: `✅ Registro de motorista criado automaticamente`
- Erros: `❌ Erro ao criar registro de motorista automaticamente`

## Suporte

Se houver problemas:
1. Verifique os logs do Supabase
2. Confirme que o trigger foi criado corretamente
3. Execute novamente a consulta de verificação
4. Entre em contato com o suporte técnico se necessário