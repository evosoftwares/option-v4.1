# Read (Select)

Padrão no cliente Supabase:
- Leitura de coleção: await supabase.from('tabela').select().eq('coluna','valor');
- Única linha: await supabase.from('tabela').select().eq('id', id).single();
- Paginação: .range(offset, offset+limit-1)
- Ordenação: .order('created_at', ascending: false)

Boas práticas
- Para chaves únicas, use .single() para garantir 1 registro
- Padronize filtros primários (PK/FK) nos services
- Evite N+1: prefira consultas com joins via foreign tables do PostgREST (select: '*, relacao(*)') quando já habilitado
- Para streams, utilize .stream(primaryKey: ['id']) onde apropriado

Casos comuns
- Buscar trips de um passageiro
- Extrato de wallet com paginação
- Saved places do usuário logado

Erros
- Trate 406/404 conforme o caso (nenhum resultado vs erro)