import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stepper_navigation.dart';

class Step1PhoneScreen extends StatefulWidget {
  const Step1PhoneScreen({super.key});

  @override
  State<Step1PhoneScreen> createState() => _Step1PhoneScreenState();
}

class _Step1PhoneScreenState extends State<Step1PhoneScreen> {
  late TextEditingController _phoneController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<StepperController>(context, listen: false);
    _phoneController = TextEditingController(text: controller.phone ?? '');
    _validatePhone(controller.phone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhone(String text) {
    // Remove todos os caracteres não numéricos
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanText.isEmpty) return '';
    
    if (cleanText.length <= 2) {
      return '(${cleanText.padRight(2, ' ')}';
    } else if (cleanText.length <= 6) {
      return '(${cleanText.substring(0, 2)}) ${cleanText.substring(2)}';
    } else if (cleanText.length <= 10) {
      return '(${cleanText.substring(0, 2)}) ${cleanText.substring(2, 6)}-${cleanText.substring(6)}';
    } else {
      return '(${cleanText.substring(0, 2)}) ${cleanText.substring(2, 7)}-${cleanText.substring(7, 11)}';
    }
  }

  void _validatePhone(String text) {
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    setState(() {
      _isValid = cleanText.length == 11;
    });
  }

  void _onPhoneChanged(String text) {
    final formatted = _formatPhone(text);
    final cursorPosition = formatted.length;
    
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );

    _validatePhone(formatted);
    
    // Atualiza o controller
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.setPhone(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Qual é o seu número?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.uberBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vamos enviar um código de verificação para este número',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.uberMediumGray,
            ),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de telefone',
              hintText: '(00) 0 0000-0000',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onChanged: _onPhoneChanged,
          ),
          const SizedBox(height: 16),
          if (!_isValid && _phoneController.text.isNotEmpty)
            const Text(
              'Por favor, insira um número de telefone válido com DDD',
              style: TextStyle(
                color: AppTheme.uberRed,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}