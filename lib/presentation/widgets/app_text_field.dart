import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// TextField padronizado seguindo o design system
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.focusNode,
    this.style,
    this.filled = true,
    this.contentPadding,
    this.borderRadius,
    this.backgroundColor,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextStyle? style;
  final bool filled;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      autofocus: autofocus,
      style: style ?? AppTypography.bodyLarge.copyWith(
        color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: backgroundColor ?? (filled 
            ? colorScheme.surfaceContainerHighest 
            : null),
        contentPadding: contentPadding ?? AppSpacing.paddingMd,
        border: _buildBorder(colorScheme.outline),
        enabledBorder: _buildBorder(colorScheme.outlineVariant),
        focusedBorder: _buildBorder(colorScheme.primary, width: 2),
        errorBorder: _buildBorder(colorScheme.error),
        focusedErrorBorder: _buildBorder(colorScheme.error, width: 2),
        disabledBorder: _buildBorder(colorScheme.outlineVariant.withOpacity(0.38)),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
}

/// TextField para busca
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTextField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      prefixIcon: Icon(
        Icons.search,
        color: colorScheme.onSurfaceVariant,
        size: AppSpacing.iconMd,
      ),
      suffixIcon: controller?.text.isNotEmpty ?? false
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
              onPressed: onClear ?? () {
                controller?.clear();
                onChanged?.call('');
              },
            )
          : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    );
  }
}

/// TextField para senha
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.labelText = 'Senha',
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      prefixIcon: Icon(
        Icons.lock_outline,
        color: colorScheme.onSurfaceVariant,
        size: AppSpacing.iconMd,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: colorScheme.onSurfaceVariant,
          size: AppSpacing.iconMd,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}

/// TextField para email
class AppEmailField extends StatelessWidget {
  const AppEmailField({
    super.key,
    this.controller,
    this.labelText = 'E-mail',
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator ?? _defaultEmailValidator,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icon(
        Icons.email_outlined,
        color: colorScheme.onSurfaceVariant,
        size: AppSpacing.iconMd,
      ),
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite seu e-mail';
    }
    
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Digite um e-mail válido';
    }
    
    return null;
  }
}

/// TextField para telefone
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    this.controller,
    this.labelText = 'Telefone',
    this.hintText = '(11) 99999-9999',
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator ?? _defaultPhoneValidator,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: Icon(
        Icons.phone_outlined,
        color: colorScheme.onSurfaceVariant,
        size: AppSpacing.iconMd,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
        _PhoneInputFormatter(),
      ],
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite seu telefone';
    }
    
    final numbers = value.replaceAll(RegExp(r'\D'), '');
    if (numbers.length < 10) {
      return 'Digite um telefone válido';
    }
    
    return null;
  }
}

/// Formatador para campo de telefone
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numbers = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    if (numbers.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    var formatted = '';
    
    if (numbers.isNotEmpty) {
      formatted += '(${numbers.substring(0, 2.clamp(0, numbers.length))}';
    }
    if (numbers.length >= 3) {
      formatted += ') ${numbers.substring(2, 7.clamp(2, numbers.length))}';
    }
    if (numbers.length >= 8) {
      formatted += '-${numbers.substring(7, 11.clamp(7, numbers.length))}';
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}