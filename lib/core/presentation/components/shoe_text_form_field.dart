import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';

class ShoeTextFormField extends StatefulWidget {
  const ShoeTextFormField({
    super.key,
    this.hintText,
    this.controller,
    this.obscureText,
    this.labelText,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.readOnly = false,
  });

  final String? hintText;
  final TextEditingController? controller;
  final bool? obscureText;
  final String? labelText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  final bool readOnly;

  @override
  State<ShoeTextFormField> createState() => _ShoeTextFormFieldState();
}

class _ShoeTextFormFieldState extends State<ShoeTextFormField> {
  late bool _obscured = widget.obscureText ?? false;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText ?? false;

    return Column(
      children: [
        widget.labelText != null
            ? Align(
                alignment: Alignment.centerLeft,
                child: ExcludeSemantics(
                  child: Text(
                    widget.labelText!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : SizedBox.shrink(),
        Semantics(
          label: widget.labelText,
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscured,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            onFieldSubmitted: widget.onFieldSubmitted,
            readOnly: widget.readOnly,
            style: widget.readOnly
                ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  )
                : Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              fillColor: AppColors.secondaryColor,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
              filled: true,
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      tooltip: _obscured ? 'Mostrar senha' : 'Ocultar senha',
                      icon: Icon(
                        _obscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
