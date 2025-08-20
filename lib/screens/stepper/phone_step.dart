import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_mask.dart';
import '../../utils/phone_validator.dart';

class PhoneStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(String)? onSave;

  const PhoneStep({
    super.key,
    required this.onNext,
    this.onSave,
  });

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<StepperController>(context, listen: false);
    _phoneController.text = controller.phone ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    return PhoneValidator.validate(value);
  }

  Future<void> _submitPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = Provider.of<StepperController>(context, listen: false);
      final phone = _phoneController.text;
      
      controller.setPhone(phone);
      widget.onSave?.call(phone);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar telefone: $e'),
            backgroundColor: AppTheme.uberRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Qual é o seu número?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vamos enviar um código para verificar seu número',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.uberLightGray,
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              inputFormatters: [PhoneInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Número de telefone',
                labelStyle: TextStyle(color: AppTheme.uberLightGray),
                hintText: '(00) 00000-0000',
                hintStyle: TextStyle(color: AppTheme.uberMediumGray),
                prefixText: '+55 ',
                prefixStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.uberMediumGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.uberMediumGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.uberWhite),
                ),
              ),
              validator: _validatePhone,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.uberWhite,
                  foregroundColor: AppTheme.uberBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uberBlack),
                        ),
                      )
                    : const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}