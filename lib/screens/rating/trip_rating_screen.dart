import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/supabase/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

/// Tela de avaliação pós-viagem
/// Permite motorista avaliar passageiro e vice-versa
class TripRatingScreen extends StatefulWidget {
  const TripRatingScreen({
    super.key,
    required this.tripId,
    required this.isDriver,
    this.onRatingCompleted,
  });

  static const String routeName = '/trip_rating';

  final String tripId;
  final bool isDriver; // true = motorista avaliando passageiro
  final VoidCallback? onRatingCompleted;

  static TripRatingScreen fromArgs(Map<String, dynamic>? args) {
    return TripRatingScreen(
      tripId: args?['tripId'] as String? ?? '',
      isDriver: args?['isDriver'] as bool? ?? false,
    );
  }

  @override
  State<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends State<TripRatingScreen> {
  final TripService _tripService = TripService(Supabase.instance.client);
  
  Trip? _trip;
  int _selectedRating = 0;
  String _comment = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    try {
      final trip = await _tripService.getTrip(widget.tripId);
      if (mounted) {
        setState(() {
          _trip = trip;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados da viagem: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma avaliação'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Determinar qual avaliação estamos enviando
      final driverRating = widget.isDriver ? null : _selectedRating.toDouble();
      final passengerRating = widget.isDriver ? _selectedRating.toDouble() : null;

      await _tripService.rateTrip(
        tripId: widget.tripId,
        driverRating: driverRating,
        passengerRating: passengerRating,
      );

      if (mounted) {
        // Mostrar sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Callback para notificar conclusão
        widget.onRatingCompleted?.call();

        // Voltar para a tela anterior ou home
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.isDriver ? '/driver_home' : '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _setRating(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _selectedRating;
        
        return GestureDetector(
          onTap: () => _setRating(starIndex),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(
              Icons.star,
              size: 40,
              color: isSelected ? AppColors.warning : AppColors.gray300,
            ),
          ),
        );
      }),
    );
  }

  String get _ratingText {
    switch (_selectedRating) {
      case 1:
        return 'Muito ruim';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Boa';
      case 5:
        return 'Excelente';
      default:
        return 'Toque nas estrelas para avaliar';
    }
  }

  String get _questionText {
    return widget.isDriver 
        ? 'Como foi sua experiência com o passageiro?'
        : 'Como foi sua experiência com o motorista?';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Avaliar viagem'),
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Avaliar viagem'),
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar viagem'),
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Ícone de sucesso
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 40,
                          color: AppColors.success,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text(
                        'Viagem concluída!',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: AppTypography.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Informações da viagem
                      if (_trip != null) ...[
                        AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: AppSpacing.sm,
                                      height: AppSpacing.sm,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _trip!.originAddress,
                                        style: AppTypography.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 2,
                                        height: AppSpacing.lg,
                                        color: AppColors.gray300,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Container(
                                      width: AppSpacing.sm,
                                      height: AppSpacing.sm,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _trip!.destinationAddress,
                                        style: AppTypography.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      
                      // Pergunta de avaliação
                      Text(
                        _questionText,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Estrelas de avaliação
                      _buildRatingStars(),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Texto da avaliação
                      Text(
                        _ratingText,
                        style: AppTypography.titleMedium.copyWith(
                          color: _selectedRating > 0 ? AppColors.warning : AppColors.gray500,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Campo de comentário (opcional)
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Comentário (opcional)',
                          hintText: 'Adicione um comentário sobre a viagem...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        maxLength: 200,
                        onChanged: (value) => _comment = value,
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              
              // Botões de ação
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPrimary,
                        foregroundColor: AppColors.lightOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightOnPrimary),
                              ),
                            )
                          : const Text(
                              'Finalizar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  TextButton(
                    onPressed: _isSubmitting ? null : () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        widget.isDriver ? '/driver_home' : '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Pular avaliação'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}