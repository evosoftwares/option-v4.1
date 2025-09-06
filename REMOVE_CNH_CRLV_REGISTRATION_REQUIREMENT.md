# Remoção da Exigência de CNH e CRLV no Cadastro de Motoristas

## 1. Problema Identificado

O processo de cadastro de motoristas exigia o upload obrigatório de fotos da CNH e CRLV, criando fricção desnecessária no fluxo de registro. Muitos motoristas já possuem esses documentos em nosso sistema e não deveriam precisar enviá-los novamente.

## 2. Solução Proposta

Tornar o upload de CNH e CRLV opcional no processo de cadastro, mantendo a funcionalidade para motoristas que desejam enviar documentos atualizados.

## 3. Alterações Realizadas

### 3.1. Atualização do Controller (`driver_stepper_controller.dart`)

1. **Modificação do método `completeDriverRegistration()`**:
   - Removida a validação obrigatória de CNH e CRLV
   - Upload de documentos tornou-se opcional
   - Atualização condicional das URLs no banco de dados

2. **Atualização da validação**:
   - `canProceedFromDocuments` renomeado para `canProceedFromCodeOfConduct`
   - Retorna sempre `true` pois é um passo informativo

### 3.2. Atualização da Interface

1. **Substituição do passo de documentos**:
   - `DriverDocumentsStep` removido
   - `DriverCodeOfConductStep` adicionado como substituto

2. **Atualização do fluxo**:
   - Passo 0: Código de Conduta (informativo)
   - Passo 1: Registro do Veículo
   - Passo 2: Finalização

### 3.3. Atualização dos Testes

1. **Testes unitários ajustados**:
   - Atualização das expectativas de validação
   - Remoção das validações obrigatórias de documentos

## 4. Benefícios da Solução

1. **Melhoria da Experiência do Usuário**:
   - Redução de passos obrigatórios no cadastro
   - Processo mais rápido e intuitivo
   - Menos fricção para motoristas já cadastrados

2. **Manutenção da Funcionalidade**:
   - Motoristas ainda podem enviar documentos se desejarem
   - Sistema continua funcionando para novos cadastros
   - Dados já existentes são preservados

3. **Flexibilidade Aumentada**:
   - Processo de cadastro mais leve
   - Opção de enviar documentos posteriormente
   - Melhor alinhamento com a experiência do usuário

## 5. Fluxo Atualizado

1. **Passo 0: Código de Conduta**
   - Informações sobre boas práticas de condução
   - Regras e expectativas para motoristas
   - Passo informativo, sempre permitido

2. **Passo 1: Registro do Veículo**
   - Dados do veículo (marca, modelo, ano, placa, cor)
   - Categoria do veículo
   - Validação obrigatória dos campos

3. **Passo 2: Finalização**
   - Revisão das informações
   - Envio opcional de CNH/CRLV
   - Confirmação do cadastro

## 6. Considerações Técnicas

- O sistema continua aceitando uploads de CNH e CRLV quando fornecidos
- Documentos existentes no banco de dados continuam válidos
- A API foi ajustada para lidar com campos opcionais
- Testes atualizados para refletir o novo comportamento