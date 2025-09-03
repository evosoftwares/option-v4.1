# Relatório de Análise — Fluxo de Cadastro de Motorista

Este documento consolida a análise detalhada do fluxo de cadastro de motorista, evidências concretas extraídas dos logs (prints e mensagens de erro no código), pontos críticos/vulnerabilidades e recomendações priorizadas de correção.

---

## 1) Descrição detalhada do fluxo atual

Resumo do fluxo observado nos controladores e serviços:
- Captura/seleção das fotos de documentos:
  - CNH e CRLV são capturadas/selecionadas via câmera/galeria e armazenadas em estado interno do controlador. Evidências:
    - driver_stepper_controller.dart: campos internos e setters para CNH/CRLV e estados de upload
      - "File? _cnhPhoto;", "File? _crlvPhoto;", "String? _cnhUrl;", "String? _crlvUrl;" (linhas 24–33)
      - Flags de tentativa e re‑tentativa: "_cnhRetryAttempt", "_crlvRetryAttempt", "_cnhIsRetrying", "_crlvIsRetrying" (linhas 36–39)
- Upload dos documentos:
  - Upload para a pasta/bucket: folder: 'driver-documents' (linha 334)
  - Tratamento e mapeamento de erros comuns durante upload:
    - Sessão expirada/token: mensagens mapeadas para "Sessão expirada. Faça login novamente." (linhas 355–362)
    - Permissão negada no Storage (Firebase): mapeado para mensagem específica (linha 362)
- Orquestração do cadastro completo:
  - Método que realiza upload de CNH e CRLV com controle de retries, armazena URLs e prossegue para persistência no banco (linhas 401–456)
  - Em seguida, garante existência do registro de motorista e atualiza dados (CNH/CRLV e dados do veículo), tratando erros de Postgrest (PGRST116, 23505)
- Garantia da sessão válida antes de operações sensíveis:
  - Rotina de verificação e eventual refresh do token de sessão com logs detalhados sobre expiração e renovação (linhas 600+):
    - Prints: "Estado da sessão", "Token expirado, renovando sessão...", "Sessão renovada com sucesso", "Sessão válida" e falhas de refresh

Integrações relevantes:
- Supabase (tabelas app_users e drivers) com RLS em múltiplas partes do projeto e scripts de diagnóstico/correção.
- Storage utilizado para documentos do motorista sob bucket "driver-documents".
- Há referências e documentação para upload via Firebase Storage com regras próprias, originando erros de permissão/sessão expirada se mal configurado.

---

## 2) Pontos críticos e possíveis vulnerabilidades

- Bucket inexistente ou mal configurado para documentos do motorista:
  - Causa de erro "Operação não suportada no namespace CNH" quando o bucket driver-documents não existe.
- RLS (Row Level Security) bloqueando operações de Storage:
  - Upload falha silenciosamente ou retorna erros de permissão, mesmo com UI exibindo "Enviado" em alguns cenários.
- Divergência de provedores de Storage (Supabase vs Firebase):
  - Regras do Firebase não reconhecem tokens do Supabase, gerando "Sessão expirada" no upload.
- Constraints e validações no banco:
  - Constraint de vehicle_category com valores incorretos/antigos pode causar falhas ao persistir motorista.
  - Violação 23505 (duplicidade) para dados como placa.
  - PGRST116 (no rows returned) em fluxos que assumem retorno obrigatório.
- Robustez de sessão:
  - Embora exista verificação/refresh, falhas de renovação derrubam o fluxo de upload/persistência se não tratadas no ponto correto.
- Experiência do usuário (UX):
  - Mensagens de erro podem ser genéricas; falta feedback específico e instruções de ação (ex.: revisar sessão, checar permissões de Storage, etc.).

---

## 3) Análise dos logs com evidências concretas

Evidências coletadas diretamente dos prints e mensagens presentes no código e nos artefatos do repositório:

- Upload para bucket/pasta dos documentos:
  - driver_stepper_controller.dart: "folder: 'driver-documents'" (linha 334)
- Mapeamento de erros de sessão/permissão no upload:
  - driver_stepper_controller.dart:
    - "sessão expirada"/"token expirado" -> "Sessão expirada. Faça login novamente." (linhas 355–362)
    - "Permissão negada no Firebase Storage. Verifique a configuração." (linha 362)
- Fluxo de upload/orquestração com estados e tentativas:
  - driver_stepper_controller.dart: blocos de upload com retries e atualização de URLs/erros (linhas 401–456)
- Persistência e tratamento de erros de banco:
  - driver_stepper_controller.dart:
    - Tratamento PGRST116 (No rows returned) (linha 491)
    - Tratamento 23505 (duplicidade) (linha 493)
  - user_service.dart e wallet_service.dart contêm handling adicional:
    - 23505 (unique violation) em criação de motorista
- Criação automática de registro do motorista e logs de sucesso:
  - driver_stepper_controller.dart: "Registro de motorista criado com sucesso: <driverId>" (linha 563)
- Sessão/refresh e logs detalhados:
  - driver_stepper_controller.dart: prints
    - "Estado da sessão" / "Token expirado, renovando sessão..." / "Sessão renovada com sucesso" / "Sessão validada" (bloco a partir de ~linha 600)
- Diagnóstico de RLS impactando Storage:
  - DIAGNOSTICO_UPLOAD_FOTO_FINAL.md: identifica RLS habilitado nas tabelas de Storage causando erros como "new row violates row-level security policy" e orienta desabilitar RLS para este projeto
- Bucket ausente e erro de "namespace CNH":
  - SOLUCAO_ERRO_NAMESPACE_CNH.md: causa principal é a ausência do bucket "driver-documents"; passos para criá-lo e desabilitar RLS
- Constraint vehicle_category com valores padronizados:
  - fix_driver_registration_errors.sql: drop/recreate constraint com valores válidos: ('economico', 'standard', 'premium', 'suv', 'executivo', 'van')
- Regras do Firebase e erro "Sessão expirada":
  - FIREBASE_STORAGE_FIX.md: explica que o Firebase Storage não reconhece tokens do Supabase e como ajustar Security Rules, caso Firebase seja mantido.

---

## 4) Recomendações de correção e melhoria

P0 — Indisponibilidade/erro de Storage
- Garantir a existência do bucket "driver-documents" e sua configuração:
  - Criar bucket se ausente e desabilitar RLS nas tabelas storage.objects e storage.buckets (conforme política do projeto sem RLS)
  - Verificar acesso de listagem/upload/URL pública para driver-documents
- Padronizar provedor de Storage:
  - Preferir Supabase Storage neste MVP (sem RLS) para evitar incompatibilidade de tokens
  - Se Firebase for inevitável, aplicar as Security Rules propostas e validar geração de URLs e permissões

P0 — Sessão e autenticação
- Forçar verificação/refresh de sessão imediatamente antes do upload e da atualização no banco
- Em caso de falha de refresh, bloquear continuidade com CTA para novo login

P1 — Banco e constraints
- Atualizar a constraint drivers_vehicle_category_check conforme script, migrar linhas inválidas e padronizar valores
- Tratar 23505 (duplicidade) de placa com validação preventiva (já existe checagem cliente) e mensagens claras
- Tratar PGRST116 com fallback e mensagens específicas

P1 — UX e observabilidade
- Mensagens de erro específicas e acionáveis (ex.: "Sessão expirada — refaça login"; "Permissão no Storage — contate suporte/atualize app")
- Acrescentar IDs/correlation IDs nos logs de upload e persistência para cruzar eventos
- Testes automatizados de sanity para bucket/permissão/URL pública (há scripts de verificação no repo)

P2 — Robustez do fluxo
- Pré‑checks assíncronos antes de iniciar upload (bucket ok, sessão ok, espaço/limite de tamanho, mime type)
- Telemetria de taxa de falha por etapa (upload CNH, upload CRLV, persistência driver)

---

## 5) Priorização dos problemas identificados

- P0
  - Bucket "driver-documents" ausente ou mal configurado (causa de "namespace CNH" e falhas de upload)
  - RLS ativo no Storage impedindo upload/list/URL pública (deve ficar desabilitado neste MVP)
  - Sessão expirada e falha de refresh não tratada no ponto crítico
- P1
  - Constraint vehicle_category inconsistente e dados legados inválidos
  - Duplicidade 23505 (ex.: placa) sem UX consistente
  - PGRST116 (no rows returned) sem fallback explícito
- P2
  - Mensagens genéricas e baixa observabilidade
  - Pré‑checks e telemetria ausentes

---

## Apêndice — Arquivos e trechos relevantes

- lib/controllers/driver_stepper_controller.dart
  - folder: 'driver-documents' (linha 334)
  - Mapeamento de erros: sessão expirada e permissão negada (linhas 355–362)
  - Upload/orquestração com estados (linhas 401–456)
  - Tratamento PGRST116 e 23505 (linhas 491–493)
  - Log de sucesso na criação do motorista (linha 563)
  - Verificação/refresh de sessão com logs (bloco ~600+)
- lib/services/user_service.dart e lib/services/wallet_service.dart
  - Criação automática do registro do motorista e tratamento 23505
- fix_driver_registration_errors.sql
  - Correção da constraint vehicle_category e desabilitar RLS no Storage
- DIAGNOSTICO_UPLOAD_FOTO_FINAL.md / SOLUCAO_ERRO_NAMESPACE_CNH.md / FIREBASE_STORAGE_FIX.md
  - Evidências e correções para RLS no Storage, bucket ausente e regras do Firebase

---

## Checklist rápido de ação

1) Storage (P0)
- [ ] Criar bucket "driver-documents" e desabilitar RLS nas tabelas de Storage
- [ ] Validar upload/listagem/URL pública do bucket
2) Sessão (P0)
- [ ] Revalidar/refresh da sessão imediatamente antes de upload/persistência
- [ ] Tratamento explícito de falha de refresh com CTA de login
3) Banco (P1)
- [ ] Atualizar constraint de vehicle_category e migrar dados inválidos
- [ ] Garantir UX de duplicidade (23505) e fallback para PGRST116
4) UX/Observabilidade (P1–P2)
- [ ] Mensagens específicas, correlação de logs e testes de sanity automáticos