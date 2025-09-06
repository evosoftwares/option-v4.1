import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/driver_document_service.dart';
import '../services/driver_document_refresh_service.dart';
import '../utils/storage_url_freshner.dart';
import '../widgets/driver_document_card_fresh.dart';

/// Exemplo de integração entre DriverDocumentService e o sistema de URLs frescas
/// Demonstra diferentes abordagens para garantir URLs sem cache
class DriverDocumentIntegrationExample extends StatefulWidget {
  final String driverId;

  const DriverDocumentIntegrationExample({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  State<DriverDocumentIntegrationExample> createState() => _DriverDocumentIntegrationExampleState();
}

class _DriverDocumentIntegrationExampleState extends State<DriverDocumentIntegrationExample> {
  final DriverDocumentRefreshService _refreshService = DriverDocumentRefreshService(Supabase.instance.client);
  
  List<dynamic> _documents = [];
  Map<String, String> _freshUrls = {};
  bool _isLoading = true;
  String _selectedMethod = 'cards';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  /// Método 1: Usando DriverDocumentService com URLs frescas via RPC
  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      // Busca documentos usando o DriverDocumentService tradicional
      final documents = await DriverDocumentService.getDriverDocuments(widget.driverId);
      
      setState(() {
        _documents = documents.map((doc) => doc.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar documentos: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Método 2: Usando DriverDocumentRefreshService para URLs frescas
  Future<void> _loadFreshUrlsOnly() async {
    setState(() => _isLoading = true);
    
    try {
      // Busca apenas URLs frescas
      final freshUrls = await _refreshService.getFreshDocumentUrls(widget.driverId);
      
      setState(() {
        _freshUrls = freshUrls;
        _selectedMethod = 'urls';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar URLs frescas: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Método 3: Usando StorageUrlFreshner diretamente
  Future<void> _loadWithDirectFreshner() async {
    setState(() => _isLoading = true);
    
    try {
      // Primeiro busca documentos
      final documents = await DriverDocumentService.getDriverDocuments(widget.driverId);
      
      // Depois aplica URLs frescas diretamente
      final freshDocuments = await StorageUrlFreshner.getDriverDocumentsWithFreshUrls(widget.driverId);
      
      setState(() {
        _documents = freshDocuments;
        _selectedMethod = 'direct';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao aplicar URLs frescas diretamente: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Método 4: Usando widgets com URLs frescas integradas
  Future<void> _loadWithFreshWidgets() async {
    setState(() => _isLoading = true);
    
    try {
      // Busca documentos
      final documents = await DriverDocumentService.getDriverDocuments(widget.driverId);
      
      setState(() {
        _documents = documents.map((doc) => doc.toJson()).toList();
        _selectedMethod = 'cards';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar documentos para widgets: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Limpa o cache de URLs
  Future<void> _clearUrlCache() async {
    StorageUrlFreshner.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache de URLs limpo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração de Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearUrlCache,
            tooltip: 'Limpar cache de URLs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de método
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Método:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedMethod,
                  items: const [
                    DropdownMenuItem(value: 'cards', child: Text('Widgets com URLs Frescas')),
                    DropdownMenuItem(value: 'urls', child: Text('Apenas URLs Frescas')),
                    DropdownMenuItem(value: 'direct', child: Text('Freshner Direto')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMethod = value);
                      switch (value) {
                        case 'cards':
                          _loadWithFreshWidgets();
                          break;
                        case 'urls':
                          _loadFreshUrlsOnly();
                          break;
                        case 'direct':
                          _loadWithDirectFreshner();
                          break;
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Estatísticas do cache
          _buildCacheStats(),
          
          // Conteúdo principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheStats() {
    final stats = StorageUrlFreshner.getCacheStats();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Cache', stats['total_cached'].toString()),
            _buildStatItem('URLs Válidas', stats['valid_urls'].toString()),
            _buildStatItem('URLs Expiradas', stats['expired_urls'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedMethod) {
      case 'cards':
        return _buildCardsView();
      case 'urls':
        return _buildUrlsView();
      case 'direct':
        return _buildDirectView();
      default:
        return const Center(child: Text('Método não implementado'));
    }
  }

  /// Visualização com widgets de cartão (URLs frescas integradas)
  Widget _buildCardsView() {
    if (_documents.isEmpty) {
      return const Center(child: Text('Nenhum documento encontrado'));
    }
    
    return ListView.builder(
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index] as Map<String, dynamic>;
        return DriverDocumentCardFresh(
          document: document,
          onRefresh: () {
            // Recarrega a URL fresca específica
            _loadWithFreshWidgets();
          },
        );
      },
    );
  }

  /// Visualização simples com apenas URLs
  Widget _buildUrlsView() {
    if (_freshUrls.isEmpty) {
      return const Center(child: Text('Nenhuma URL fresca disponível'));
    }
    
    return ListView(
      children: _freshUrls.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(_getDocumentTypeName(entry.key)),
            subtitle: Text(
              entry.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                // Abrir URL em um visualizador
                _openUrl(entry.value);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Visualização com documentos processados diretamente
  Widget _buildDirectView() {
    if (_documents.isEmpty) {
      return const Center(child: Text('Nenhum documento encontrado'));
    }
    
    return ListView.builder(
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index] as Map<String, dynamic>;
        final documentType = document['document_type'] as String;
        final fileUrl = document['file_url'] as String;
        final isFresh = document['is_fresh_url'] == true;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              isFresh ? Icons.check_circle : Icons.cached,
              color: isFresh ? Colors.green : Colors.orange,
            ),
            title: Text(_getDocumentTypeName(documentType)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                if (isFresh)
                  const Text(
                    'URL fresca',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                // Atualiza URL específica
                await _updateSingleDocumentUrl(documentType);
              },
            ),
          ),
        );
      },
    );
  }

  /// Atualiza URL de um documento específico
  Future<void> _updateSingleDocumentUrl(String documentType) async {
    try {
      final freshUrl = await _refreshService.getFreshDocumentUrl(
        widget.driverId,
        documentType,
      );
      
      if (freshUrl != null) {
        setState(() {
          _freshUrls[documentType] = freshUrl;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL atualizada para $documentType'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Abre URL em visualizador externo
  void _openUrl(String url) {
    // Implementar abertura de URL
    // Pode usar url_launcher ou um visualizador interno
    print('📎 Abrindo URL: $url');
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
}

/// Exemplo de uso em uma página
class DriverDocumentIntegrationPage extends StatelessWidget {
  final String driverId;

  const DriverDocumentIntegrationPage({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DriverDocumentIntegrationExample(driverId: driverId);
  }
}