# Upload de Documentos do Motorista

## Visão Geral

Este documento descreve o sistema de upload de documentos para motoristas, incluindo CNH (Carteira Nacional de Habilitação) e CRLV (Certificado de Registro e Licenciamento de Veículo).

## Configuração

### 1. Supabase Storage

#### Bucket Configuration
- **ID**: driver-documents
- **Nome**: driver-documents
- **Público**: Sim
- **Tipo**: STANDARD
- **Limite de Tamanho**: 10 MB (10485760 bytes)
- **Tipos MIME Permitidos**:
  - image/jpeg
  - image/png
  - image/webp
  - image/jpg
  - application/pdf
- **Criado em**: 2025-08-29T02:40:55.764Z
- **Atualizado em**: 2025-08-29T02:40:55.764Z

#### Bucket user-photos (Referência)
- **ID**: user-photos
- **Nome**: user-photos
- **Público**: Sim
- **Tipo**: STANDARD
- **Limite de Tamanho**: 50 MB (52428800 bytes)
- **Tipos MIME Permitidos**:
  - image/jpeg
  - image/png
  - image/webp
  - image/jpg

#### Variáveis de Ambiente
```bash
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 2. Estrutura de Arquivos

```
lib/
├── controllers/
│   └── driver_stepper_controller.dart  # Controla o fluxo de cadastro
├── services/
│   └── file_upload_service.dart         # Serviço de upload de arquivos
└── utils/
    └── supabase_helper.dart             # Helper para Supabase
```

## Funcionalidades

### FileUploadService

O `FileUploadService` fornece métodos para upload de documentos com validação robusta:

#### Métodos Principais

- `uploadDriverDocument()`: Upload específico para documentos de motorista
- `uploadImage()`: Upload genérico para imagens

#### Validações Implementadas

1. **Existência do Arquivo**
   - Verifica se o arquivo existe antes do upload

2. **Tamanho do Arquivo**
   - Limite máximo: 10MB para documentos
   - Limite máximo: 5MB para imagens gerais

3. **Formato do Arquivo**
   - Documentos: JPG, JPEG, PNG, PDF
   - Imagens: JPG, JPEG, PNG, WEBP

4. **Compressão Automática**
   - Imagens são comprimidas automaticamente (exceto PDFs)
   - Qualidade de compressão: 85%
   - Dimensões máximas: 1920x1080

### DriverStepperController

Controla o fluxo de cadastro do motorista com upload de documentos:

#### Métodos Principais

- `takeCnhPhoto()`: Captura foto da CNH
- `takeCrlvPhoto()`: Captura foto do CRLV
- `completeDriverRegistration()`: Finaliza o cadastro com upload dos documentos

#### Validações de Negócio

1. **Usuário Autenticado**
   - Verifica se o usuário está logado

2. **Documentos Obrigatórios**
   - CNH e CRLV são obrigatórios

3. **Tratamento de Erros**
   - Mensagens específicas para cada tipo de erro
   - Loading states durante o processo

## Processo de Upload

### Fluxo Normal

1. **Seleção de Documentos**
   ```dart
   await controller.takeCnhPhoto();  // Captura CNH
   await controller.takeCrlvPhoto(); // Captura CRLV
   ```

2. **Validação Local**
   - Verificação de formato
   - Verificação de tamanho
   - Compressão se necessário

3. **Upload para Supabase**
   ```dart
   final url = await FileUploadService.uploadDriverDocument(
     file: documentFile,
     bucket: 'driver-documents',
     path: 'user_id/document_name.ext',
   );
   ```

4. **Atualização do Perfil**
   - URLs dos documentos são salvos no perfil do usuário

### Estrutura de Paths

```
driver-documents/
├── {user_id}/
│   ├── cnh_{timestamp}.{ext}
│   └── crlv_{timestamp}.{ext}
```

## Troubleshooting

### Problemas Comuns

#### 1. Bucket não encontrado

**Erro**: `Bucket 'driver-documents' not found`

**Soluções**:
1. Verificar se o bucket existe no Supabase Storage
2. Executar o script de criação:
   ```bash
   python setup_driver_documents_bucket.py
   ```
3. Criar manualmente via SQL:
   ```sql
   INSERT INTO storage.buckets (id, name, public)
   VALUES ('driver-documents', 'driver-documents', true);
   ```

#### 2. Permissões insuficientes

**Erro**: `Insufficient permissions`

**Soluções**:
1. Verificar se o usuário está autenticado
2. Verificar políticas RLS no Supabase
3. Usar service role key para operações administrativas

#### 3. Arquivo muito grande

**Erro**: `File size exceeds maximum allowed`

**Soluções**:
1. Verificar limite de 10MB
2. Comprimir imagem antes do upload
3. Converter PDF para imagem se necessário

#### 4. Formato não suportado

**Erro**: `File format not supported`

**Soluções**:
1. Verificar extensões permitidas: JPG, JPEG, PNG, PDF
2. Converter arquivo para formato suportado
3. Verificar MIME type do arquivo

### Logs de Debug

Para ativar logs detalhados:

```dart
// No FileUploadService
print('Uploading file: ${file.path}');
print('File size: ${await file.length()} bytes');
print('MIME type: ${lookupMimeType(file.path)}');
```

### Testes

Executar testes de upload:

```bash
# Testes unitários
flutter test test/integration/cnh_upload_test.dart

# Testes de integração
flutter test test/integration/

# Todos os testes
flutter test
```

### Monitoramento

#### Métricas Importantes

1. **Taxa de Sucesso de Upload**
   - Meta: > 95%
   - Monitorar falhas por tipo de erro

2. **Tempo de Upload**
   - Meta: < 30 segundos para arquivos de 10MB
   - Considerar compressão para melhorar performance

3. **Uso de Storage**
   - Monitorar crescimento do bucket
   - Implementar limpeza de arquivos antigos se necessário

#### Alertas

- Taxa de erro > 5%
- Tempo de upload > 60 segundos
- Uso de storage > 80% do limite

## Configurações Avançadas

### Compressão Personalizada

```dart
// Ajustar qualidade de compressão
static const int compressionQuality = 85;

// Ajustar dimensões máximas
static const int maxImageWidth = 1920;
static const int maxImageHeight = 1080;
```

### Retry Logic

Implementar retry automático para uploads falhados:

```dart
int maxRetries = 3;
int currentRetry = 0;

while (currentRetry < maxRetries) {
  try {
    return await uploadDocument();
  } catch (e) {
    currentRetry++;
    if (currentRetry >= maxRetries) rethrow;
    await Future.delayed(Duration(seconds: currentRetry * 2));
  }
}
```

### Cache Local

Implementar cache para evitar re-uploads:

```dart
// Verificar se arquivo já foi enviado
final cachedUrl = await getCachedUrl(fileHash);
if (cachedUrl != null) return cachedUrl;
```

## Segurança

### Boas Práticas

1. **Validação no Cliente e Servidor**
   - Nunca confiar apenas na validação do cliente
   - Implementar validação dupla

2. **Sanitização de Nomes**
   - Remover caracteres especiais dos nomes de arquivo
   - Usar timestamps para evitar conflitos

3. **Verificação de Conteúdo**
   - Verificar headers de arquivo
   - Implementar antivírus se necessário

4. **Rate Limiting**
   - Limitar número de uploads por usuário
   - Implementar cooldown entre uploads

### Diretrizes de Desenvolvimento

#### Convenções de Nomenclatura
Para documentos de motorista, use o padrão:
```
driver-documents/{driver_id}/{document_type}/{filename}.{extension}
```

Exemplos:
- `driver-documents/123e4567-e89b-12d3-a456-426614174000/cnh/cnh_frente.jpg`
- `driver-documents/123e4567-e89b-12d3-a456-426614174000/crlv/crlv.pdf`

#### Acesso a Arquivos
1. **Acesso Público**: Arquivos podem ser acessados diretamente via URL:
   ```
   https://qlbwacmavngtonauxnte.supabase.co/storage/v1/object/public/driver-documents/{file_path}
   ```

2. **URLs Assinadas**: Para acesso temporário (se necessário):
   ```dart
   final signedUrl = await supabase.storage
       .from('driver-documents')
       .createSignedUrl('path/to/file', 3600); // 1 hora
   ```

#### Tratamento de Erros Específicos
- **Limite de Tamanho**: Informar usuário e sugerir compressão
- **Tipo MIME**: Mostrar tipos aceitos em mensagem amigável
- **Erros de Rede**: Implementar retry automático

#### Melhores Práticas
1. **Organização**: Use pastas (prefixos) para organizar arquivos
2. **Nomes Únicos**: Gere nomes únicos para evitar colisões (UUIDs/timestamps)
3. **Segurança**: Revise permissões regularmente
4. **Limpeza**: Implemente estratégia para deletar arquivos não utilizados

### Políticas RLS Recomendadas

```sql
-- Política para leitura (usuários podem ver seus próprios documentos)
CREATE POLICY "Users can view own documents" ON storage.objects
FOR SELECT USING (auth.uid()::text = (storage.foldername(name))[1]);

-- Política para upload (usuários podem fazer upload em sua pasta)
CREATE POLICY "Users can upload to own folder" ON storage.objects
FOR INSERT WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);
```

## Manutenção

### Limpeza Periódica

```sql
-- Remover arquivos órfãos (sem referência no perfil)
DELETE FROM storage.objects 
WHERE bucket_id = 'driver-documents' 
AND created_at < NOW() - INTERVAL '30 days'
AND name NOT IN (
  SELECT cnh_url FROM driver_profiles WHERE cnh_url IS NOT NULL
  UNION
  SELECT crlv_url FROM driver_profiles WHERE crlv_url IS NOT NULL
);
```

### Backup

1. **Backup Automático**
   - Configurar backup diário do bucket
   - Manter backups por 30 dias

2. **Backup Manual**
   ```bash
   # Fazer backup manual do bucket
   supabase storage cp driver-documents/ ./backup/driver-documents/ --recursive
   ```

## Exemplo de Implementação Completa

Baseado na documentação oficial dos buckets Supabase:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

final supabase = Supabase.instance.client;

// Upload de documento de motorista
Future<String?> uploadDriverDocument(
  Uint8List fileBytes, 
  String fileName, 
  String driverId, 
  String documentType
) async {
  try {
    final fileOptions = FileOptions(
      cacheControl: '3600',
      upsert: false,
      contentType: _determineContentType(fileName),
    );

    final filePath = 'driver-documents/$driverId/$documentType/$fileName';
    
    final response = await supabase.storage
        .from('driver-documents')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: fileOptions,
        );

    return response; // Caminho do arquivo enviado
  } on StorageException catch (error) {
    // Tratar erros específicos de storage
    print('Erro de storage: ${error.message}');
    return null;
  } catch (error) {
    // Tratar outros erros
    print('Erro inesperado: $error');
    return null;
  }
}

// Obter URL pública do arquivo
String getDriverDocumentUrl(String filePath) {
  return supabase.storage
      .from('driver-documents')
      .getPublicUrl(filePath);
}

// Download de arquivo
Future<Uint8List?> downloadDriverDocument(String filePath) async {
  try {
    final data = await supabase.storage
        .from('driver-documents')
        .download(filePath);
    return data; // Uint8List do conteúdo do arquivo
  } on StorageException catch (error) {
    print('Erro no download: ${error.message}');
    return null;
  } catch (error) {
    print('Erro inesperado: $error');
    return null;
  }
}

// Determinar tipo de conteúdo baseado na extensão
String _determineContentType(String fileName) {
  final extension = fileName.toLowerCase().split('.').last;
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}
```
   # Exportar lista de arquivos
   supabase storage ls driver-documents --recursive > backup_list.txt
   ```

### Atualizações

1. **Versionamento de API**
   - Manter compatibilidade com versões anteriores
   - Documentar breaking changes

2. **Migração de Dados**
   - Planejar migração para novos formatos
   - Manter dados antigos durante transição

## Contato

Para suporte técnico ou dúvidas sobre implementação, consulte:

- Documentação do Supabase Storage
- Issues no repositório do projeto
- Equipe de desenvolvimento