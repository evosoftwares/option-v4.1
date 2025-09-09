import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver_document.dart';
import '../services/driver_document_service.dart';
import '../services/driver_document_refresh_service.dart';
import '../utils/storage_url_freshner.dart';
import '../widgets/driver_document_card_fresh.dart';

/// Exemplo completo de uso do sistema de URLs frescas para documentos do motorista
class DriverDocumentExample extends StatefulWidget {
  const DriverDocumentExample({super.key});

  @override
  State<DriverDocumentExample> createState() => _DriverDocumentExampleState();
}

class _DriverDocumentExampleState extends State<DriverDocumentExample> {
  final String driverId = 'motorista-123'; // ID do motorista atual
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;
  String? _error;
  final DriverDocumentRefreshService _refreshService =
      DriverDocumentRefreshService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadDriverDocuments();
  }

  /// Carrega os documentos do motorista com URLs frescas
  Future<void> _loadDriverDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Método 1: Usar o serviço direto com RPC
      final documents =
          await DriverDocumentService.getDriverDocuments(driverId);

      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar documentos: $e';
        _isLoading = false;
      });
    }
  }

  /// Atualiza URL fresca para um documento específico
  Future<void> _refreshDocumentUrl(String documentType) async {
    try {
      final freshUrl =
          await _refreshService.getFreshDocumentUrl(driverId, documentType);

      // Atualiza o documento na lista
      setState(() {
        final index = _documents
            .indexWhere((doc) => doc['document_type'] == documentType);
        if (index != -1) {
          _documents[index] = Map<String, dynamic>.from(_documents[index])
            ..['file_url'] = freshUrl;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'URL atualizada para ${getDocumentTypeName(documentType)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Atualiza todas as URLs dos documentos
  Future<void> _refreshAllDocumentUrls() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtém URLs frescas para todos os documentos
      final freshUrls = await _refreshService.getFreshDocumentUrls(driverId);

      // Atualiza cada documento
      setState(() {
        _documents = _documents.map((doc) {
          final freshUrl = freshUrls[doc['document_type']];
          if (freshUrl != null) {
            return Map<String, dynamic>.from(doc)..['file_url'] = freshUrl;
          }
          return doc;
        }).toList();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas as URLs foram atualizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar URLs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Limpa o cache de URLs
  Future<void> _clearUrlCache() async {
    StorageUrlFreshner.clearCache();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache de URLs limpo'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos do Motorista'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverDocuments,
            tooltip: 'Recarregar documentos',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearUrlCache,
            tooltip: 'Limpar cache',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de ações
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _refreshAllDocumentUrls,
                  icon: const Icon(Icons.update),
                  label: const Text('Atualizar Todas URLs'),
                ),
                const SizedBox(width: 8),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _documents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDriverDocuments,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum documento encontrado'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return DriverDocumentCardFresh(
          document: document,
          onRefresh: () =>
              _refreshDocumentUrl(document['document_type'] as String),
        );
      },
    );
  }

  /// Obtém o nome amigável do tipo de documento
  String getDocumentTypeName(String type) {
    final names = {
      'cnh_front': 'CNH (Frente)',
      'cnh_back': 'CNH (Verso)',
      'crlv': 'CRLV',
      'vehicle_front': 'Veículo (Frente)',
      'vehicle_back': 'Veículo (Traseira)',
      'vehicle_left': 'Veículo (Lado Esquerdo)',
      'vehicle_right': 'Veículo (Lado Direito)',
      'vehicle_interior': 'Interior do Veículo',
    };
    return names[type] ?? type;
  }
}

/// Widget de exemplo para demonstrar uso em outras partes do app
class DriverDocumentSection extends StatelessWidget {
  final String driverId;

  const DriverDocumentSection({
    super.key,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Documentos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    // Navega para a tela completa de documentos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverDocumentExample(),
                      ),
                    );
                  },
                  tooltip: 'Ver todos os documentos',
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DriverDocumentService.getDriverDocuments(driverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }

                final documents = snapshot.data ?? [];

                if (documents.isEmpty) {
                  return const Text('Nenhum documento encontrado');
                }

                return Column(
                  children: documents.take(3).map((doc) {
                    return ListTile(
                      leading: Icon(
                          _getDocumentIcon(doc['document_type'] as String)),
                      title: Text(
                          _getDocumentName(doc['document_type'] as String)),
                      subtitle: Text(_getStatusText(doc['status'] as String)),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          try {
                            final service = DriverDocumentRefreshService(
                                Supabase.instance.client);
                            // ignore: unused_local_variable
                            final freshUrl = await service.getFreshDocumentUrl(
                              driverId,
                              doc['document_type'] as String,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URL atualizada com sucesso'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao atualizar URL: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType) {
      case 'cnh_front':
      case 'cnh_back':
        return Icons.credit_card;
      case 'crlv':
        return Icons.assignment;
      case 'vehicle_front':
      case 'vehicle_back':
      case 'vehicle_left':
      case 'vehicle_right':
      case 'vehicle_interior':
        return Icons.directions_car;
      default:
        return Icons.description;
    }
  }

  String _getDocumentName(String documentType) {
    final names = {
      'cnh_front': 'CNH (Frente)',
      'cnh_back': 'CNH (Verso)',
      'crlv': 'CRLV',
      'vehicle_front': 'Veículo (Frente)',
      'vehicle_back': 'Veículo (Traseira)',
      'vehicle_left': 'Veículo (Lado Esquerdo)',
      'vehicle_right': 'Veículo (Lado Direito)',
      'vehicle_interior': 'Interior do Veículo',
    };
    return names[documentType] ?? documentType;
  }

  String _getStatusText(String status) {
    final statusNames = {
      'pending': 'Pendente',
      'approved': 'Aprovado',
      'rejected': 'Rejeitado',
      'expired': 'Expirado',
    };
    return statusNames[status] ?? status;
  }
}

/// Exemplo de uso em uma página de perfil do motorista
class DriverProfilePage extends StatelessWidget {
  final String driverId;

  const DriverProfilePage({
    super.key,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Motorista'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Informações básicas do motorista
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações Pessoais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Nome'),
                      subtitle: Text('Nome do Motorista'), // Buscar do banco
                    ),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Email'),
                      subtitle:
                          Text('motorista@example.com'), // Buscar do banco
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Seção de documentos usando o widget de exemplo
            DriverDocumentSection(driverId: driverId),

            const SizedBox(height: 16),

            // Botão para ver todos os documentos
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverDocumentExample(),
                    ),
                  );
                },
                icon: const Icon(Icons.description),
                label: const Text('Gerenciar Documentos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
