import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/supabase/driver_excluded_zone.dart';

import '../../services/secure_driver_excluded_zones_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/logo_branding.dart';

/// Tela de gerenciamento de zonas excluídas do motorista
/// Sistema simplificado baseado em palavras-chave com 2 passos:
/// Passo 1: Selecionar tipo de zona (Rua/Avenida, Bairro, Cidade)
/// Passo 2: Digite a palavra-chave para exclusão
class DriverExcludedZonesScreen extends StatefulWidget {
  const DriverExcludedZonesScreen({super.key});

  @override
  State<DriverExcludedZonesScreen> createState() =>
      _DriverExcludedZonesScreenState();
}

class _DriverExcludedZonesScreenState extends State<DriverExcludedZonesScreen> {
  // === SERVIÇOS ===
  /// Serviço seguro para gerenciar zonas excluídas com validações
  late final SecureDriverExcludedZonesService _service;

  // === CONTROLADORES ===
  /// Controlador para o campo de entrada da palavra-chave
  final TextEditingController _keywordController = TextEditingController();
  /// Chave do formulário para validação
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // === ESTADO DA TELA ===
  /// Lista de zonas excluídas carregadas do banco de dados
  List<DriverExcludedZone> _excludedZones = [];
  /// Indica se está carregando dados do servidor
  bool _isLoading = true;
  /// ID do motorista logado - obtido do contexto de autenticação
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _service = SecureDriverExcludedZonesService(Supabase.instance.client);
    _loadDriverData();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await UserService.getCurrentUser();
      print('DEBUG - Usuário atual: ${user?.id}, tipo: ${user?.userType}');

      if (user?.userType == 'driver') {
        _driverId = user!.id;
        print('DEBUG - Driver ID definido: $_driverId');
        await _loadExcludedZones();
      } else {
        print('DEBUG - Usuário não é motorista ou não encontrado');
      }
    } catch (e) {
      print('DEBUG - Erro ao carregar dados do motorista: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar dados do motorista: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carrega todas as zonas excluídas do motorista do banco de dados
  /// Atualiza a lista local com os dados mais recentes
  Future<void> _loadExcludedZones() async {
    // Verifica se temos o ID do motorista necessário
    if (_driverId == null) {
      print('DEBUG - Driver ID é null, não é possível carregar zonas');
      return;
    }

    try {
      // Busca todas as zonas excluídas do motorista no banco
      final zones = await _service.getDriverExcludedZones(_driverId!);
      print('DEBUG - Zonas carregadas: ${zones.length} zonas encontradas');

      // Atualiza o estado local com as zonas carregadas
      if (mounted) {
        setState(() {
          _excludedZones = zones;
        });
      }
    } catch (e) {
      print('DEBUG - Erro ao carregar zonas: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar zonas excluídas: $e');
      }
    }
  }


  /// Remove uma zona excluída específica do motorista
  /// Chama o serviço para deletar do banco e atualiza a lista local
  Future<void> _removeExcludedZone(DriverExcludedZone zone) async {
    try {
      // Remove a zona do banco de dados
      await _service.removeExcludedZone(zone.id);

      // Recarrega a lista para refletir a remoção
      await _loadExcludedZones();

      if (mounted) {
        _showSuccessSnackBar('Zona excluída removida com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao remover zona excluída: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// PASSO 1: Exibe diálogo para selecionar o tipo de zona a excluir
  /// Opções: Rua/Avenida, Bairro, Cidade
  /// Sistema simplificado sem busca de endereço
  Future<void> _showZoneTypeSelectionDialog() async {
    // Define as opções de tipos de zona disponíveis
    final zoneOptions = [
      {
        'type': 'rua',
        'icon': Icons.add_road,
        'title': 'Rua/Avenida',
        'description': 'Excluir uma rua ou avenida específica\n(ex: "Av. Paulista", "Rua Augusta")',
      },
      {
        'type': 'bairro',
        'icon': Icons.location_city,
        'title': 'Bairro',
        'description': 'Excluir um bairro completo\n(ex: "Centro", "Copacabana")',
      },
      {
        'type': 'cidade',
        'icon': Icons.location_on,
        'title': 'Cidade',
        'description': 'Excluir uma cidade inteira\n(ex: "São Paulo", "Rio de Janeiro")',
      },
    ];

    // Exibe o diálogo de seleção de tipo
    final selectedOption = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Escolha o tipo de exclusão'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Texto explicativo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Selecione o que você deseja excluir das suas zonas de trabalho:',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de opções de tipo de zona
                ...zoneOptions.map((option) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(
                      option['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      option['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    // Se o usuário selecionou um tipo, prossegue para o passo 2
    if (selectedOption != null && mounted) {
      await _showKeywordInputDialog(selectedOption);
    }
  }

  /// PASSO 2: Exibe diálogo para capturar a palavra-chave
  /// Campo de texto simples onde o usuário digita o que deseja excluir
  Future<void> _showKeywordInputDialog(Map<String, dynamic> zoneType) async {
    // Limpa o campo antes de exibir
    _keywordController.clear();

    // Define texto de ajuda baseado no tipo selecionado
    String hintText;
    String helperText;
    List<String> examples;

    switch (zoneType['type'] as String) {
      case 'rua':
        hintText = 'Digite o nome da rua ou avenida';
        helperText = 'Nome completo ou parte do nome da via';
        examples = ['Av. Paulista', 'Rua Augusta', 'Marginal Tietê'];
        break;
      case 'bairro':
        hintText = 'Digite o nome do bairro';
        helperText = 'Nome do bairro que deseja excluir';
        examples = ['Centro', 'Copacabana', 'Vila Madalena'];
        break;
      case 'cidade':
        hintText = 'Digite o nome da cidade';
        helperText = 'Nome da cidade que deseja excluir';
        examples = ['São Paulo', 'Rio de Janeiro', 'Belo Horizonte'];
        break;
      default:
        hintText = 'Digite a palavra-chave';
        helperText = 'Termo que deseja excluir';
        examples = ['Exemplo'];
    }

    // Exibe o diálogo de entrada de palavra-chave
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(zoneType['icon'] as IconData, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('Excluir ${zoneType['title']}'),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explicação do que será feito
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text('Você não receberá corridas em:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qualquer ${zoneType['title'].toString().toLowerCase()} que contenha a palavra digitada',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de entrada da palavra-chave
                TextFormField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    labelText: zoneType['title'] as String,
                    hintText: hintText,
                    helperText: helperText,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(zoneType['icon'] as IconData),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite a palavra-chave para exclusão';
                    }
                    if (value.trim().length < 2) {
                      return 'Digite pelo menos 2 caracteres';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Exemplos para ajudar o usuário
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text('Exemplos:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        examples.join(', '),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Adicionar Exclusão'),
            ),
          ],
        );
      },
    );

    // Se o usuário confirmou, adiciona a zona excluída
    if (confirmed == true && mounted) {
      await _addZoneWithKeyword(zoneType);
    }
  }

  /// Adiciona uma nova zona excluída com a palavra-chave digitada pelo usuário
  /// Salva no banco de dados e atualiza a lista local
  Future<void> _addZoneWithKeyword(Map<String, dynamic> zoneType) async {
    try {
      // Obtém dados do formulário
      final keyword = _keywordController.text.trim();
      final type = zoneType['type'] as String;

      print('DEBUG - Adicionando zona: type=$type, keyword=$keyword');

      // Chama o serviço para salvar no banco
      final zone = await _service.addExcludedZoneWithType(
        driverId: _driverId!,
        keyword: keyword,
        zoneType: type,
        city: 'N/A', // Sistema simplificado não requer cidade específica
        state: 'N/A', // Sistema simplificado não requer estado específico
      );

      print('DEBUG - Zona salva com sucesso: ${zone.id}');

      // Recarrega a lista para mostrar a nova zona
      await _loadExcludedZones();

      // Exibe mensagem de sucesso
      _showSuccessSnackBar(
        'Exclusão adicionada: $keyword (${zoneType['title']})',
      );
    } catch (error) {
      print('DEBUG - Erro ao salvar zona: $error');
      _showErrorSnackBar('Erro ao salvar exclusão: ${error.toString()}');
    }
  }

  /// Inicia o processo de adição de nova zona excluída
  /// Sistema simplificado: apenas verifica autenticação e chama o primeiro passo
  Future<void> _showAddZoneDialog() async {
    // Verifica se o motorista está identificado
    if (_driverId == null) {
      _showErrorSnackBar('Erro: Motorista não identificado');
      return;
    }

    // Inicia o processo de 2 passos: primeiro seleciona o tipo
    await _showZoneTypeSelectionDialog();
  }

  /// Exibe diálogo de confirmação antes de remover uma zona excluída
  /// Mostra informações claras sobre o que será removido usando displayName
  void _showRemoveConfirmation(DriverExcludedZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Zona Excluída'),
        content: Text(
          'Deseja remover "${zone.displayName}" das suas zonas excluídas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeExcludedZone(zone);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const StandardAppBar(
        title: 'Zonas Excluídas',
        showMenuIcon: true,
        showBackButton: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: _driverId != null
          ? FloatingActionButton(
              onPressed: _showAddZoneDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExcludedZones,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Zonas de Exclusão',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Defina áreas onde você não deseja receber corridas',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimary.withOpacity(0.9),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Você pode adicionar quantas zonas quiser. O app não enviará corridas com origem nessas áreas.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Excluded Zones List
                    if (_excludedZones.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.location_on,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Nenhuma zona excluída',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Toque no botão + para adicionar uma zona',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5),
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zonas Excluídas (${_excludedZones.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _excludedZones.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final zone = _excludedZones[index];
                              return AppCard(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_off,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                  title: Text(
                                    zone.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: zone.isKeywordBased
                                    ? Text('${zone.city}, ${zone.state}')
                                    : Text('${zone.city}, ${zone.state}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _showRemoveConfirmation(zone),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Constrói o estado vazio quando não há zonas excluídas
  /// Mostra ilustração e instruções sobre o novo sistema
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone ilustrativo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Título do estado vazio
          Text(
            'Nenhuma zona excluída',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Instruções sobre o novo sistema
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Use o botão acima para adicionar palavras-chave e excluir ruas, bairros ou cidades específicas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Exemplos de uso do sistema
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text('Exemplos de exclusões:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• Rua: "Av. Paulista", "Rua Augusta"', style: TextStyle(fontSize: 13)),
                const Text('• Bairro: "Centro", "Copacabana"', style: TextStyle(fontSize: 13)),
                const Text('• Cidade: "São Paulo", "Rio de Janeiro"', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a lista de zonas excluídas
  /// Cada item mostra a palavra-chave e tipo usando displayName
  Widget _buildZonesList(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da lista com contador
        Text(
          'Exclusões Ativas (${_excludedZones.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Lista scrollável das zonas excluídas
        Expanded(
          child: ListView.builder(
            itemCount: _excludedZones.length,
            itemBuilder: (context, index) {
              final zone = _excludedZones[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: ListTile(
                    // Ícone indicativo de exclusão
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off,
                        color: colorScheme.error,
                      ),
                    ),

                    // Título: usa displayName para mostrar keyword e tipo corretamente
                    // Ex: "Centro (Bairro)" ou "Av. Paulista (Rua/Avenida)"
                    title: Text(
                      zone.displayName, // ✅ Usa propriedade correta que trata keyword-based e legacy
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Subtítulo: mostra informações adicionais se disponíveis
                    subtitle: zone.isKeywordBased
                        ? Text('Tipo: ${zone.zoneType?.toUpperCase() ?? "N/A"}')
                        : Text('${zone.city}, ${zone.state}'), // Para zonas legadas

                    // Botão de remoção
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remover exclusão',
                      onPressed: () => _showRemoveConfirmation(zone),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
