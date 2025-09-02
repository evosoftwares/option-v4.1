# Create (Insert)

Padrão no cliente Supabase para Flutter/Dart:

- Inserção simples retornando a linha criada:
  await supabase.from('tabela').insert(payload).select().single();

- Inserção múltipla (lista de mapas):
  await supabase.from('tabela').insert(listaPayload).select();

Boas práticas
- Sempre encadear .select() para obter os dados efetivos criados (auditoria/validação)
- Preferir validações no app e constraints no DB (NOT NULL, UNIQUE, FK) para evitar dados inválidos
- Para domínios financeiros, logue toda criação em wallet_transactions e evite mutações posteriores
- Envelopar em um service por domínio e capturar exceções de rede/servidor

Exemplos frequentes no projeto
- Criar saved_place para um usuário
- Adicionar payment_method
- Registrar uso de promo_code

Tratamento de erros
- Capturar PostgrestException e mapear mensagens amigáveis
- Implementar retries com backoff quando fizer sentido