import 'package:flutter/material.dart';

class DriverEligibilityStatusCard extends StatelessWidget {
  final Map<String, dynamic> eligibilityStatus;
  final VoidCallback? onFixIssues;

  const DriverEligibilityStatusCard({
    super.key,
    required this.eligibilityStatus,
    this.onFixIssues,
  });

  @override
  Widget build(BuildContext context) {
    final canGoOnline = eligibilityStatus['canGoOnline'] as bool;
    final reason = eligibilityStatus['reason'] as String?;
    final message = eligibilityStatus['message'] as String;
    final documentsStatus = eligibilityStatus['documentsStatus'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: canGoOnline
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.orange.shade50, Colors.red.shade50],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(canGoOnline, reason),
                const SizedBox(height: 16),
                _buildMessage(message),
                if (documentsStatus != null) ...[
                  const SizedBox(height: 20),
                  _buildDocumentsStatus(documentsStatus),
                ],
                if (!canGoOnline && onFixIssues != null) ...[
                  const SizedBox(height: 20),
                  _buildActionButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool canGoOnline, String? reason) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: canGoOnline ? Colors.green : Colors.orange,
            boxShadow: [
              BoxShadow(
                color: (canGoOnline ? Colors.green : Colors.orange).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            canGoOnline ? Icons.check_circle : Icons.warning_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canGoOnline ? 'Elegível para ficar Online' : 'Não Elegível',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (reason != null)
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStatus(Map<String, dynamic> documentsStatus) {
    final pendingDocs = documentsStatus['pendingDocuments'] as List<String>? ?? [];
    final rejectedDocs = documentsStatus['rejectedDocuments'] as List<String>? ?? [];
    final missingDocs = documentsStatus['missingDocuments'] as List<String>? ?? [];
    final approvedDocs = documentsStatus['approvedDocuments'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status dos Documentos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (approvedDocs.isNotEmpty)
          _buildDocumentGroup(
            title: 'Aprovados',
            documents: approvedDocs,
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            backgroundColor: Colors.green.shade50,
          ),
        
        if (pendingDocs.isNotEmpty)
          _buildDocumentGroup(
            title: 'Em Análise',
            documents: pendingDocs,
            icon: Icons.schedule_rounded,
            color: Colors.orange,
            backgroundColor: Colors.orange.shade50,
          ),
        
        if (missingDocs.isNotEmpty)
          _buildDocumentGroup(
            title: 'Não Enviados',
            documents: missingDocs,
            icon: Icons.upload_file_rounded,
            color: Colors.blue,
            backgroundColor: Colors.blue.shade50,
          ),
        
        if (rejectedDocs.isNotEmpty)
          _buildDocumentGroup(
            title: 'Rejeitados',
            documents: rejectedDocs,
            icon: Icons.cancel_rounded,
            color: Colors.red,
            backgroundColor: Colors.red.shade50,
          ),
      ],
    );
  }

  Widget _buildDocumentGroup({
    required String title,
    required List<String> documents,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...documents.map((doc) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDocumentDisplayName(doc),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onFixIssues,
        icon: const Icon(Icons.build_rounded, size: 20),
        label: const Text(
          'Resolver Pendências',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  String _getDocumentDisplayName(String documentType) {
    switch (documentType) {
      case 'CNH_FRONT':
        return 'CNH (Frente)';
      case 'CNH_BACK':
        return 'CNH (Verso)';
      case 'CRLV':
        return 'CRLV (Documento do Veículo)';
      case 'PROFILE_PHOTO':
        return 'Foto do Perfil';
      case 'VEHICLE_PHOTO':
        return 'Foto do Veículo';
      default:
        return documentType.replaceAll('_', ' ');
    }
  }
}