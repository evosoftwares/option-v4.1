# Remoção das Telas de Envio de CNH e CRLV

## 1. Problema Identificado

Atualmente, o fluxo de documentação exige que motoristas reenviem a CNH e CRLV mesmo que já tenham sido enviados durante o cadastro. Isso cria fricção na experiência do usuário.

## 2. Solução Proposta

Remover as telas de envio de CNH e CRLV do stepper de documentos, considerando os documentos já enviados na tabela `drivers` como válidos. Substituir por um fluxo de envio de fotos do veículo.

## 3. Arquivos a Serem Modificados

### 3.1. Atualizar driver_documents_stepper.dart

O arquivo foi atualizado para remover os steps de CNH e CRLV e incluir steps para envio de fotos do veículo:
- Foto do Veículo - Frente
- Foto do Veículo - Trás
- Foto do Veículo - Esquerda
- Foto do Veículo - Direita
- Interior do Veículo

### 3.2. Criar driver_vehicle_photo_step.dart

Foi criado um novo componente `DriverVehiclePhotoStep` para lidar com o envio de fotos do veículo.

### 3.3. Atualizar driver_document_service.dart

O método `getDocumentationStatus` foi atualizado para:
1. Remover CNH e CRLV da lista de documentos obrigatórios a serem enviados
2. Considerar CNH e CRLV da tabela `drivers` como documentos já aprovados
3. Adicionar os 5 tipos de documentos do veículo como obrigatórios

## 4. Benefícios da Solução

1. **Eliminação da Duplicidade**: Motoristas não precisam enviar os mesmos documentos duas vezes
2. **Melhoria da UX**: Experiência mais fluida e intuitiva
3. **Redução de Fricção**: Menos passos no processo de documentação
4. **Compatibilidade**: Mantém funcionalidade com documentos existentes
5. **Feedback Visual**: Interface clara sobre status dos documentos

Essas atualizações resolverão completamente o problema da duplicidade de documentos, melhorando significativamente a experiência do usuário.