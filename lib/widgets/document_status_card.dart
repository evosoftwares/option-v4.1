import 'package:flutter/material.dart';

enum DocumentStatus { approved, pending, rejected, missing }

class DocumentStatusCard extends StatefulWidget {
  final String documentType;
  final DocumentStatus status;
  final String? rejectionReason;
  final VoidCallback? onUpload;
  final VoidCallback? onView;
  final bool isAnimated;

  const DocumentStatusCard({
    super.key,
    required this.documentType,
    required this.status,
    this.rejectionReason,
    this.onUpload,
    this.onView,
    this.isAnimated = true,
  });

  @override
  State<DocumentStatusCard> createState() => _DocumentStatusCardState();
}

class _DocumentStatusCardState extends State<DocumentStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimated) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAnimated) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildCard(),
            ),
          );
        },
      );
    }
    
    return _buildCard();
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getGradient(),
            border: Border.all(
              color: _getStatusColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildStatusInfo(),
                if (widget.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  _buildRejectionReason(),
                ],
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor().withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDocumentDisplayName(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    String infoText;
    IconData infoIcon;
    Color infoColor;

    switch (widget.status) {
      case DocumentStatus.approved:
        infoText = 'Documento aprovado e válido para uso no app.';
        infoIcon = Icons.check_circle_outline;
        infoColor = Colors.green;
        break;
      case DocumentStatus.pending:
        infoText = 'Documento em análise. Aguarde nossa verificação.';
        infoIcon = Icons.schedule_outlined;
        infoColor = Colors.orange;
        break;
      case DocumentStatus.rejected:
        infoText = 'Documento rejeitado. Veja o motivo abaixo e reenvie.';
        infoIcon = Icons.error_outline;
        infoColor = Colors.red;
        break;
      case DocumentStatus.missing:
        infoText = 'Documento obrigatório ainda não foi enviado.';
        infoIcon = Icons.upload_file_outlined;
        infoColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: infoColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(infoIcon, color: infoColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              infoText,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReason() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motivo da Rejeição:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.rejectionReason!,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.status == DocumentStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onView,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Visualizar Documento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green[700],
            side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (widget.status != DocumentStatus.missing)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onView,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Visualizar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        if (widget.status != DocumentStatus.missing) const SizedBox(width: 12),
        Expanded(
          flex: widget.status == DocumentStatus.missing ? 1 : 1,
          child: ElevatedButton.icon(
            onPressed: widget.onUpload,
            icon: Icon(
              widget.status == DocumentStatus.missing 
                ? Icons.upload_file_rounded 
                : Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(
              widget.status == DocumentStatus.missing ? 'Enviar' : 'Reenviar',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradient() {
    Color baseColor = _getStatusColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: 0.1),
        baseColor.withValues(alpha: 0.05),
        Colors.white,
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.missing:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case DocumentStatus.approved:
        return Icons.check_circle_rounded;
      case DocumentStatus.pending:
        return Icons.schedule_rounded;
      case DocumentStatus.rejected:
        return Icons.cancel_rounded;
      case DocumentStatus.missing:
        return Icons.upload_file_rounded;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case DocumentStatus.approved:
        return 'APROVADO';
      case DocumentStatus.pending:
        return 'EM ANÁLISE';
      case DocumentStatus.rejected:
        return 'REJEITADO';
      case DocumentStatus.missing:
        return 'PENDENTE';
    }
  }

  String _getDocumentDisplayName() {
    switch (widget.documentType) {
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
        return widget.documentType.replaceAll('_', ' ');
    }
  }
}