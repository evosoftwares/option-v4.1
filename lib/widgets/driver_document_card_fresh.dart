import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/storage_url_freshner.dart';

/// Widget que exibe um documento do motorista com URL fresca
/// Evita problemas de cache usando URLs assinadas
class DriverDocumentCardFresh extends StatefulWidget {
  final Map<String, dynamic> document;
  final VoidCallback? onRefresh;
  final bool showStatus;

  const DriverDocumentCardFresh({
    super.key,
    required this.document,
    this.onRefresh,
    this.showStatus = true,
  });

  @override
  State<DriverDocumentCardFresh> createState() => _DriverDocumentCardFreshState();
}

class _DriverDocumentCardFreshState extends State<DriverDocumentCardFresh> {
  String? _freshUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFreshUrl();
  }

  @override
  void didUpdateWidget(DriverDocumentCardFresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document['id'] != widget.document['id']) {
      _loadFreshUrl();
    }
  }

  Future<void> _loadFreshUrl() async {
    setState(() => _isLoading = true);
    
    try {
      final originalUrl = widget.document['file_url'] as String;
      final storagePath = _extractStoragePath(originalUrl);
      
      if (storagePath != null) {
        final freshUrl = await StorageUrlFreshner.getFreshSignedUrl(
          bucket: 'driver-documents',
          filePath: storagePath,
        );
        
        if (mounted) {
          setState(() {
            _freshUrl = freshUrl;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _freshUrl = originalUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar URL fresca: $e');
      setState(() {
        _freshUrl = widget.document['file_url'] as String;
        _isLoading = false;
      });
    }
  }

  String? _extractStoragePath(String fullUrl) {
    try {
      final uri = Uri.parse(fullUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length > 1) {
        return pathSegments.sublist(1).join('/');
      }
    } catch (e) {
      print('❌ Erro ao extrair path: $e');
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentType = widget.document['document_type'] as String;
    final status = widget.document['status'] as String;
    final fileSize = widget.document['file_size'] as int?;
    final updatedAt = DateTime.parse(widget.document['updated_at'] as String);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDocumentTypeName(documentType),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.showStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Imagem do documento
            if (_isLoading)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_freshUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _freshUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Informações do arquivo
            Row(
              children: [
                if (fileSize != null)
                  Text(
                    '${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () async {
                    await _loadFreshUrl();
                    if (widget.onRefresh != null) {
                      widget.onRefresh!();
                    }
                  },
                  tooltip: 'Atualizar imagem',
                ),
              ],
            ),
            
            // Data de atualização
            Text(
              'Atualizado: ${_formatDate(updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentTypeName(String type) {
    final Map<String, String> names = {
      'cnh_front': 'CNH (Frente)',
      'cnh_back': 'CNH (Verso)',
      'crlv': 'CRLV',
      'vehicle_front': 'Veículo (Frente)',
      'vehicle_back': 'Veículo (Traseira)',
      'vehicle_left': 'Veículo (Lado Esquerdo)',
      'vehicle_right': 'Veículo (Lado Direito)',
      'vehicle_interior': 'Interior do Veículo',
    };
    return names[type] ?? type.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}