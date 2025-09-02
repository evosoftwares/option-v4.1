# Update

Padrão no cliente Supabase:
- Atualização por PK: await supabase.from('tabela').update(patch).eq('id', id).select().single();
- Atualização por filtro composto: .eq('colunaA', a).eq('colunaB', b).select();

Boas práticas
- Sempre usar .select() para confirmar a linha após update
- Evitar updates destrutivos em domínios financeiros; preferir registrar nova transação
- Para concorrência otimista, considere checar updated_at antes de aplicar o patch (WHERE updated_at = valor_antigo)
- Em services, centralize regras de validação e transformação

Casos comuns
- Atualizar status de trip
- Alterar apelido de saved_place
- Marcar notificação como lida

Erros
- Trate conflitos (409) e aplique retry com política definida quando seguro