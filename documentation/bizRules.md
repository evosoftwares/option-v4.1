Especificação de Negócio Detalhada: Plataforma de Mobilidade Urbana
1. Visão Geral e Estratégia de Negócio
1.1. Conceito Central
Uma plataforma de mobilidade urbana (Ride-Hailing) que funciona como um mercado de duas faces (two-sided marketplace), conectando Passageiros que necessitam de transporte a Condutores que oferecem o serviço.

1.2. Proposta de Valor e Diferenciais
O projeto se diferencia por focar no empoderamento do Condutor e do passageiro, oferecendo um modelo de negócio mais justo e flexível com preço definido pela demanda real de mercado, onde o prestador de serviço (motorista) define o seu preço e o passageiro escolhe conforme melhor lhe aprouver, analisando inclusive o melhor custo benefício dentre os motoristas da plataforma disponíveis naquela região.

A plataforma torna isso possível, oferecendo ao motorista e ao passageiro diversas opções de escolha, dando significado ao nome da empresa (OPTION), onde o motorista escolhe as tarifas que pretende trabalhar e o passageiro escolhe o motorista conforme preços, veículos, histórico de avaliação e demais serviços oferecidos pelo motorista (transporte de pet, ar condicionado disponível, disponibilidade para mercado, condomínio etc).

Visando assim, oferecer ao passageiro e ao motorista, várias opções de controle de demanda e qualidade, e com o mínimo de cancelamentos possíveis, uma vez que todos tiveram a opção de escolher previamente as características da viagem.

Precificação Flexível: O Condutor tem controle granular sobre os componentes de distância e tempo do valor da corrida.

Controle sobre Serviços: O Condutor define previamente quais serviços adicionais oferece e as taxas correspondentes.

Controle Geográfico: O Condutor pode excluir bairros ou zonas onde não deseja atuar.

Transparência e Escolha: O Passageiro escolhe ativamente o Condutor desejado de uma lista filtrada e transparente, já sabendo o preço final, a avaliação do motorista, o tipo de veículo (incluindo o ano) e se o motorista está com ar ligado, desligado ou a disposição. Assim, o passageiro poderá escolher o motorista dentre outros que estiverem disponíveis (em um raio de até 10km), analisando o custo benefício ao comparar os preços, os veículos e histórico de avaliação de cada motorista.

O objetivo estratégico é atrair e reter os melhores veículos e condutores, com o menor índice de cancelamentos, o que, por consequência, resultará em um serviço de maior qualidade e disponibilidade para os Passageiros, criando um ciclo virtuoso de crescimento.

2. Atores do Ecossistema
O Passageiro (Passenger): O cliente final. Utiliza a aplicação para solicitar, acompanhar, pagar e avaliar viagens.

O Condutor (Driver): O prestador de serviço. Utiliza a aplicação para configurar seu perfil, definir seus preços e áreas de atuação, ficar online, aceitar e completar viagens.

O Administrador (Admin): A equipe de gestão da plataforma. Utiliza um painel de controle web para supervisionar a operação, gerir usuários, definir parâmetros globais e comunicar-se com a base de usuários.

3. Fluxo de Negócio Detalhado: Passageiro
3.1. Onboarding e Gestão de Conta
Registo:

O usuário cria uma conta usando E-mail e Senha.

Um perfil de usuário (AppUser) é criado no Firestore, associado ao seu UID do Firebase Auth.

O usuário deve aceitar os Termos de Serviço e Política de Privacidade no momento do cadastro.

Gestão de Perfil (ProfileScreen):

Visualizar e editar informações básicas (Nome, Foto, Telefone).

Endereços Salvos (SavedPlacesService):

Funcionalidade para adicionar, editar e remover endereços favoritos (ex: "Casa", "Trabalho").

Histórico de Viagens (TripHistoryService):

Acesso a uma lista de todas as viagens passadas.

3.2. Solicitação de Viagem (Fluxo Principal)
Passo 1: Definir Destino: O Passageiro insere o endereço de destino. A origem é preenchida automaticamente com a localização atual.

Passo 2: Confirmar Origem e Rota: O Passageiro ajusta o pino no mapa para o ponto de embarque exato.

Passo 3: Selecionar Categoria e Preferências:

O Passageiro seleciona a categoria do veículo (ex: "Carro Comum", "Frete").

Para transporte de passageiros, marca suas necessidades (filtros obrigatórios):

Precisa de Ar-Condicionado?

Leva Animal de Estimação (Pet)?

Precisa de Porta-Malas Grande (Mercado)?

Destino/Origem é em Condomínio?

Número de Paradas no Trajeto: (ex: 1, 2, 3).

Passo 4: Escolha do Condutor (Matching):

O sistema exibe uma lista com os 10 Condutores mais próximos que atendem aos critérios.

Cada item mostra: Foto, Nome, Avaliação, Marca, modelo, ano e cor do veículo, Preço Total, Tempo de Chegada e Distância.

Passo 5: Confirmação e Pedido:

O Passageiro toca no Condutor desejado.

O sistema verifica a disponibilidade do Condutor em tempo real.

Sucesso: A solicitação é enviada exclusivamente ao Condutor escolhido.

Concorrência: Se indisponível, o Passageiro é notificado para escolher outro.

3.3. Durante a Viagem
Aguardando Aceite: A tela do Passageiro aguarda a confirmação do Condutor.

Condutor a Caminho: Após o aceite, a interface mostra os detalhes do Condutor, sua posição no mapa, e os botões de Chat e Ligar.

Viagem Iniciada: O mapa atualiza para mostrar o progresso até o destino.

Alteração de Rota: O Passageiro pode solicitar a alteração do destino, que depende da aprovação do Condutor.

3.4. Pós-Viagem e Pagamento
Finalização: O Condutor finaliza a viagem no app.

Pagamento: A cobrança é processada automaticamente pelo Asaas.

Avaliação (RatingService): O Passageiro avalia o Condutor com estrelas e tags pré-definidas.

4. Fluxo de Negócio Detalhado: Condutor
4.1. Onboarding e Verificação
Registo Detalhado: O Condutor fornece dados pessoais, do veículo e envia fotos dos documentos (CNH, CRLV).

Aprovação Manual: O perfil fica "Pendente" até aprovação do Admin.

Alteração de Perfil: Alterações em dados críticos (veículo, CNH) requerem nova aprovação do Admin.

4.2. Configuração do Perfil de Trabalho
No seu perfil, o Condutor tem controle total sobre as seguintes configurações:

Ajuste de Ganhos (Dinâmico): O motorista pode definir um valor exato por quilômetro (em R$) ou por minuto (R$) que substitui o valor padrão da plataforma.

Preço por KM Personalizado (R$): Pode definir um valor exato por quilômetro que substitui o valor padrão da plataforma.

Preço por Minuto Personalizado (R$): Pode definir um valor exato por minuto que substitui o valor padrão da plataforma.

Política de Ar-Condicionado: Define se trabalha com ar Sempre Ligado, Sempre Desligado ou Conforme Solicitação.

Serviços Adicionais e Taxas: Ativa os serviços que oferece e define o valor fixo para cada um (Pet, Mercado, Condomínio, Paradas).

Áreas de Atendimento (Zonas de Exclusão):

O Condutor pode definir bairros onde não deseja receber solicitações.

Esta lista (excluded_neighborhoods) é salva no seu perfil no Firestore.

Nota futura: Acrescentar possibilidade do motorista definir dinâmico por bairros.

4.3. Disponibilidade e Aceitação de Viagens
Ficar Online: O Condutor ativa o botão para se tornar elegível. (Lembrete: O motorista só vai receber chamadas depois que o passageiro o escolheu).

Receber Solicitação: Ao ser escolhido, recebe uma notificação com detalhes da viagem e ganhos.

Decisão: O Condutor tem 10 segundos para Aceitar ou Recusar.

4.4. Realização da Viagem
Navegar até o Passageiro: Após aceitar, o app exibe a rota para o ponto de embarque.

Iniciar Viagem: Ao encontrar o Passageiro, inicia a viagem no app.

Navegar até o Destino: O app mostra a rota para o destino final.

Finalizar Viagem: Ao chegar, finaliza a viagem no app.

4.5. Pós-Viagem e Gestão
Ganhos: O valor da viagem (descontada a comissão) é creditado em sua carteira.

Painel de Controle: Acesso a um dashboard com histórico, ganhos e avaliações.

Avaliação: O Condutor também avalia o Passageiro.

5. Lógica Central: Matching, Precificação e Concorrência
5.1. Algoritmo de Matching (Passo a Passo)
Query Inicial: Busca Condutores online na categoria e raio de 10 km.

Filtragem por Zona de Exclusão: Remove condutores se a origem OU destino da viagem estiver em sua lista de bairros excluídos.

Filtragem por Preferências: Se a categoria for "Transporte de Passageiros", filtra com base nas preferências (Pet, Ar, etc.). Para outras categorias (Frete, Guincho), este filtro é ignorado.

Cálculo de Preço Individual: Calcula o preço para cada condutor elegível usando a fórmula abaixo.

Ordenação e Limite: Ordena a lista por distância (mais próximo primeiro).

Exibição: Os 10 primeiros Condutores são exibidos para o Passageiro.

5.2. Fórmula de Precificação
PreçoTotal = PreçoBase + TaxasAdicionais

PreçoBase = ComponenteDistancia + ComponenteTempo

ComponenteDistancia = PreçoKM_Aplicado * DistânciaTotal

PreçoKM_Aplicado é o Preço por KM Personalizado do Condutor. Se não definido, usa o ValorBaseKM da plataforma.

ComponenteTempo = PreçoMin_Aplicado * TempoTotal

PreçoMin_Aplicado é o Preço por Minuto Personalizado do Condutor. Se não definido, usa o ValorBaseMin da plataforma.

TaxasAdicionais: Soma das taxas fixas (Pet, Condomínio, etc.), incluindo a TaxaPorParada multiplicada pelo número de paradas.

Distância/Tempo Total: Incluem o trajeto do Condutor até o Passageiro e o trajeto da viagem principal.

5.3. Gerenciamento de Estado em Tempo Real e Concorrência
Listener em Tempo Real: A tela de seleção do Passageiro observa o status dos Condutores em tempo real e desativa visualmente aqueles que ficarem indisponíveis.

Transação Atômica na Seleção: A escolha do Condutor é uma transação que verifica e altera o status do Condutor de forma atômica para evitar conflitos.

6. Regras de Cancelamento e Políticas
6.1. Taxa de Cancelamento (Cobrada do Passageiro)
A taxa só é aplicável se o Passageiro cancelar DEPOIS que o Condutor aceitou e já está a caminho.

Cálculo da Multa Base:

MultaBase = MÍNIMO( (PreçoTotalEstimado * 0.20), 10.00 )

Cálculo do Fator de Deslocamento:

FatorDeslocamento = (DistânciaJáPercorridaPeloCondutor) / (DistânciaTotalAtéOPassageiro)

Cálculo da Taxa Final a ser Cobrada:

TaxaFinal = MultaBase * FatorDeslocamento

Esta taxa é cobrada do Passageiro e repassada (descontada a comissão) ao Condutor.

6.2. Direito do Condutor à Taxa por Não Comparecimento (No-Show)
Se o Condutor chega ao local de embarque e o Passageiro não aparece, o Condutor deve aguardar 3 minutos.

Após os 3 minutos, o Condutor pode cancelar a viagem, selecionando o motivo "Passageiro não apareceu".

Neste caso, ele tem direito a receber o valor da TaxaFinal de cancelamento, calculada com FatorDeslocamento = 1 (100%).

6.3. Política de Suspensão por Cancelamento Abusivo
Um sistema de "strikes" será implementado.

Se um Passageiro ou Condutor cancelar 3 viagens consecutivas (após o aceite do Condutor), sua conta será temporariamente suspensa.

A contagem de strikes é zerada após a conclusão de uma viagem.

O Administrador tem a autoridade para reativar a conta ou aplicar uma suspensão permanente em casos de abuso recorrente.

7. Sistemas Adicionais
7.1. Sistema de Pagamento
A plataforma utiliza uma abordagem focada em pagamentos digitais, oferecendo dois métodos principais:

**Métodos de Pagamento Suportados:**
- **Carteira Digital**: Sistema interno com saldo, transações e histórico completo
- **PIX**: Pagamentos instantâneos via integração com Asaas Gateway

**Fluxo de Pagamento:**
1. **Recarga da Carteira**: Passageiros podem adicionar créditos via PIX
2. **Pagamento de Viagens**: Débito automático da carteira digital
3. **Cashback**: Retorno automático em créditos na carteira
4. **Transparência**: Histórico completo de todas as transações

**Vantagens da Abordagem Digital:**
- Transações instantâneas e seguras
- Menor complexidade operacional
- Redução de custos de processamento
- Foco na experiência do usuário brasileiro
- Eliminação de problemas com troco e manuseio de dinheiro

A integração com o Asaas garante segurança e conformidade com as regulamentações financeiras brasileiras.

7.2. Sistema de Comunicação
Chat:

Baseado em Firestore, com uma collection de chats. Cada viagem (trip_id) tem seu próprio document de chat.

Permite a troca de mensagens de texto em tempo real.

O histórico do chat fica disponível para consulta no detalhe da viagem, mas em modo somente leitura após a conclusão.

Telefone:

Um botão na interface da viagem ativa uma chamada telefônica (usando o discador do celular) para o número cadastrado do outro usuário.

7.3. Painel de Administração gerenciado no supabase
O painel web deve permitir ao Admin:

Gestão de Usuários: Visualizar, aprovar, suspender e reativar contas.

Configurações Globais:

Definir o Valor Base por KM e Valor Base por Minuto para cada categoria.

Definir a percentagem de comissão da plataforma.

Comunicação: Enviar notificações push em massa ou segmentadas (inclusive por cidades).

Suporte: Visualizar detalhes de viagens para auxiliar em disputas.