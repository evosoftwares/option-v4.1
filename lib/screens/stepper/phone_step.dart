import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../utils/phone_mask.dart';
import '../../utils/phone_validator.dart';

class PhoneStep extends StatefulWidget {

  const PhoneStep({
    super.key,
    required this.onNext,
    this.onSave,
  });
  final VoidCallback onNext;
  final Function(String)? onSave;

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

  String? _validatePhone(String? value) => PhoneValidator.validate(value);

  Future<void> _submitPhone() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final controller = Provider.of<StepperController>(context, listen: false);
      final phone = _phoneController.text.trim();
      controller.setPhone(phone);
      widget.onSave?.call(phone);

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) widget.onNext();
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao salvar telefone. Por favor, tente novamente mais tarde.'),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNextPressed() {
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.setPhone(_phoneController.text.trim());
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Qual é o seu número?',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vamos enviar um código para verificar seu número',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: colorScheme.onSurface),
              inputFormatters: [PhoneInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Número de telefone',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                hintText: '(00) 00000-0000',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixText: '+55 ',
                prefixStyle: TextStyle(color: colorScheme.onSurface),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              validator: _validatePhone,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitPhone,
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
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