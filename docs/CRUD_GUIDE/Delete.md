# Delete

Padrão no cliente Supabase:
- Remoção por PK: await supabase.from('tabela').delete().eq('id', id).select().single();
- Remoção por filtro: .eq('user_id', userId).eq('location_id', locId)

Boas práticas
- Prefira soft delete (coluna deleted_at ou is_deleted) para entidades de negócio com histórico
- Para dados de configuração simples, hard delete pode ser aceitável
- Respeite FKs e ON DELETE (RESTRICT/SET NULL/CASCADE) definidas no schema
- Documente triggers (se usadas) para logs/auditoria

Casos comuns
- Remover saved_place
- Invalidar payment_method
- Apagar notificação já processada

Erros
- Trate violações de FK e informe ao usuário como resolver