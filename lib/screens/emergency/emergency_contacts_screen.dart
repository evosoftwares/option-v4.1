import 'package:flutter/material.dart';
import '../../models/emergency_contact.dart';
import '../../services/emergency_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_text_field.dart';
import '../../utils/snackbar_utils.dart';

/// Tela de configuração de contatos de emergência
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        final contacts = await EmergencyService.getEmergencyContacts(user.id);
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar contatos: $e');
      }
    }
  }

  Future<void> _addContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      SnackBarUtils.showError(context, 'Nome e telefone são obrigatórios');
      return;
    }

    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        SnackBarUtils.showError(context, 'Usuário não encontrado');
        return;
      }
      
      await EmergencyService.addEmergencyContactSimple(
        userId: user.id,
        name: _nameController.text,
        phone: _phoneController.text,
        relationship: _relationshipController.text.isEmpty 
            ? 'Contato' 
            : _relationshipController.text,
      );

      _nameController.clear();
      _phoneController.clear();
      _relationshipController.clear();
      
      await _loadContacts();
      
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(context, 'Contato adicionado com sucesso');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao adicionar contato: $e');
      }
    }
  }

  Future<void> _removeContact(String contactId) async {
    try {
      await EmergencyService.removeEmergencyContactById(contactId);
      await _loadContacts();
      
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Contato removido com sucesso');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao remover contato: $e');
      }
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Contato de Emergência'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                labelText: 'Nome',
                hintText: 'Digite o nome do contato',
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                labelText: 'Telefone',
                hintText: 'Digite o telefone',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _relationshipController,
                labelText: 'Relacionamento (opcional)',
                hintText: 'Ex: Familiar, Amigo, Cônjuge',
                prefixIcon: const Icon(Icons.family_restroom),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _phoneController.clear();
              _relationshipController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _addContact,
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showRemoveContactDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Contato'),
        content: Text(
          'Deseja remover ${contact.name} da sua lista de contatos de emergência?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeContact(contact.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Contatos de Emergência'),
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Informações sobre contatos de emergência
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Sobre os Contatos de Emergência',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Em caso de emergência, estes contatos serão notificados automaticamente '
                        'com sua localização e situação. Recomendamos adicionar pelo menos 2 contatos.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de contatos
                Expanded(
                  child: _contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.contact_emergency,
                                size: 64,
                                color: AppColors.gray400,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Nenhum contato de emergência',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Adicione contatos para serem notificados\nem caso de emergência',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            return AppCard(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.blue.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.blue,
                                  ),
                                ),
                                title: Text(
                                  contact.name,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.phone,
                                      style: AppTypography.bodyMedium,
                                    ),
                                    if (contact.relationship.isNotEmpty)
                                      Text(
                                        contact.relationship,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _showRemoveContactDialog(contact),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
}