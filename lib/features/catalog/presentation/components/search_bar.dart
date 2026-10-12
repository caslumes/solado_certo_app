import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';

class ShoeSearchBar extends StatefulWidget {
  const ShoeSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// Called from the keyboard's search action and from the search icon.
  final ValueChanged<String>? onSubmitted;

  @override
  State<ShoeSearchBar> createState() => _ShoeSearchBarState();
}

class _ShoeSearchBarState extends State<ShoeSearchBar> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSubmitted = widget.onSubmitted;

    return ShoeTextFormField(
      hintText: 'pesquise algo...',
      controller: _controller,
      onChanged: widget.onChanged,
      onFieldSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Material(
          color: AppColors.tertiaryColor,
          child: InkWell(
            onTap: onSubmitted == null
                ? null
                : () => onSubmitted(_controller.text),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.search,
                color: Colors.white,
                semanticLabel: 'Pesquisar',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
