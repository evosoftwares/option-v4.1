# Guia de CRUD (Flutter + Supabase)

Objetivo: concentrar, em um único lugar, como o app implementa operações de Create, Read, Update e Delete, com um quadro-resumo por tabela e guias pedagógicos de uso no cliente Dart/Flutter.

Estrutura
- CRUD_OVERVIEW.md: mapa "tabela por tabela" com chaves principais e services Dart que manipulam cada uma
- Create.md: guia de criação (insert) com padrões e boas práticas
- Read.md: guia de leitura (select) com filtros, paginação e .single()
- Update.md: guia de atualização (update) com retorno via .select() e cuidados
- Delete.md: guia de remoção (delete), abordando soft delete vs hard delete

Observações do projeto
- Não utilizamos RLS (Row Level Security) nem Functions no Supabase. Podemos usar Triggers, desde que bem documentadas
- Padrão do cliente: sempre retornar dados após mutações usando .select(); para leitura de uma única linha, usar .single()
- Encapsular chamadas em services por domínio, mantendo consistência de filtros (PK/FK) e validações

Atalhos
- Quadro-resumo: ./CRUD_OVERVIEW.md
- Guias: ./Create.md, ./Read.md, ./Update.md, ./Delete.md