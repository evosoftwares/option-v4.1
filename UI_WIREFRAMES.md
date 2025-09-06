# Nova UI para Fluxo de Documentação do Motorista

## Visão Geral

Com a implementação da solução técnica para eliminar a duplicidade de documentos, precisamos atualizar a UI para refletir essa mudança. O objetivo é melhorar a experiência do usuário, evitando que ele precise enviar os mesmos documentos duas vezes.

## Fluxo Atual vs. Fluxo Proposto

### Fluxo Atual
1. Cadastro do motorista (envio de CNH e CRLV)
2. Aprovação inicial
3. Acesso à tela "Documentos" onde o motorista precisa enviar novamente a CNH e CRLV
4. Nova aprovação

### Fluxo Proposto
1. Cadastro do motorista (envio de CNH e CRLV salvo diretamente em driver_documents)
2. Aprovação inicial
3. Acesso à tela "Documentos" onde o motorista vê os documentos já enviados e pode enviar documentos adicionais se necessário

## Telas Propostas

### 1. Tela de Documentos do Motorista (Atualizada)

#### Estado Atual (Documentos Enviados no Cadastro)
```
┌─────────────────────────────────────────────────────────────┐
│ Documentos Obrigatórios                          1 de 4     │
├─────────────────────────────────────────────────────────────┤
│ [✓] Documentação Completa                                   │
│     Todos os documentos foram aprovados                     │
│ ████████████████████████████████████████████████████████ 4/4 │
├─────────────────────────────────────────────────────────────┤
│ Documentos Obrigatórios Enviados                            │
├─────────────────────────────────────────────────────────────┤
│ [CNH Frente] [Aprovado]                                     │
│ Carteira Nacional de Habilitação (frente)                   │
├─────────────────────────────────────────────────────────────┤
│ [CNH Verso]  [Aprovado]                                     │
│ Carteira Nacional de Habilitação (verso)                    │
├─────────────────────────────────────────────────────────────┤
│ [CRLV]       [Aprovado]                                     │
│ Certificado de Registro e Licenciamento do Veículo          │
├─────────────────────────────────────────────────────────────┤
│ [Veículo]    [Aprovado]                                     │
│ Foto frontal do veículo                                     │
├─────────────────────────────────────────────────────────────┤
│ Documentos Opcionais                                        │
├─────────────────────────────────────────────────────────────┤
│ [Veículo Traseira] [Enviar]                                 │
│ Foto traseira do veículo                                    │
├─────────────────────────────────────────────────────────────┤
│ [Veículo Lateral Esquerda] [Enviar]                         │
│ Foto lateral esquerda do veículo                            │
├─────────────────────────────────────────────────────────────┤
│ [Veículo Lateral Direita] [Enviar]                          │
│ Foto lateral direita do veículo                             │
└─────────────────────────────────────────────────────────────┘
```

#### Estado com Documentos Pendentes
```
┌─────────────────────────────────────────────────────────────┐
│ Documentos Obrigatórios                          2 de 4     │
├─────────────────────────────────────────────────────────────┤
│ [!] Documentos Pendentes                                    │
│ 2 documento(s) precisam ser enviados para ativar sua conta  │
│ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 2/4 │
├─────────────────────────────────────────────────────────────┤
│ Documentos Obrigatórios Pendentes                           │
├─────────────────────────────────────────────────────────────┤
│ [CNH Frente] [OBRIGATÓRIO]               [Enviar]           │
│ Carteira Nacional de Habilitação (frente)                   │
├─────────────────────────────────────────────────────────────┤
│ [Veículo]    [OBRIGATÓRIO]               [Enviar]           │
│ Foto frontal do veículo                                     │
├─────────────────────────────────────────────────────────────┤
│ Documentos Obrigatórios Enviados                            │
├─────────────────────────────────────────────────────────────┤
│ [CNH Verso]  [Aprovado]                                     │
│ Carteira Nacional de Habilitação (verso)                    │
├─────────────────────────────────────────────────────────────┤
│ [CRLV]       [Aprovado]                                     │
│ Certificado de Registro e Licenciamento do Veículo          │
├─────────────────────────────────────────────────────────────┤
│ Documentos Opcionais                                        │
├─────────────────────────────────────────────────────────────┤
│ [Veículo Traseira] [Enviar]                                 │
│ Foto traseira do veículo                                    │
├─────────────────────────────────────────────────────────────┤
│ [Veículo Lateral Esquerda] [Enviar]                         │
│ Foto lateral esquerda do veículo                            │
├─────────────────────────────────────────────────────────────┤
│ [Veículo Lateral Direita] [Enviar]                          │
│ Foto lateral direita do veículo                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. Tela de Envio de Documento (Atualizada)

Quando o motorista acessa um documento que já foi enviado no cadastro, mostrar uma tela indicando que o documento já foi enviado:

```
┌─────────────────────────────────────────────────────────────┐
│ CNH - Frente                                                │
├─────────────────────────────────────────────────────────────┤
│ [✓] Documento já enviado                                    │
│ Este documento foi enviado durante o cadastro e está        │
│ aguardando aprovação.                                       │
├─────────────────────────────────────────────────────────────┤
│ [Imagem da CNH Frente]                                      │
│                                                             │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Data de Validade: 15/06/2030                                │
├─────────────────────────────────────────────────────────────┤
│ Status: Aguardando Aprovação                                │
├─────────────────────────────────────────────────────────────┤
│ [Voltar]                                                    │
└─────────────────────────────────────────────────────────────┘
```

### 3. Tela de Stepper de Documentos (Atualizada)

No fluxo de stepper, remover os passos de CNH e CRLV, mantendo apenas os documentos adicionais:

```
┌─────────────────────────────────────────────────────────────┐
│ Documentos Adicionais                            1 de 2     │
├─────────────────────────────────────────────────────────────┤
│ [Veículo - Frente]                                          │
│ Foto frontal do veículo                                     │
├─────────────────────────────────────────────────────────────┤
│ [Veículo - Traseira]                                        │
│ Foto traseira do veículo                                    │
└─────────────────────────────────────────────────────────────┘
```

## Benefícios da Nova UI

1. **Melhoria na Experiência do Usuário**: O motorista não precisa enviar os mesmos documentos duas vezes
2. **Redução de Fricção**: Menos passos no processo de documentação
3. **Clareza Visual**: Interface mais limpa e intuitiva
4. **Feedback Imediato**: O motorista sabe exatamente quais documentos já foram enviados e quais ainda faltam