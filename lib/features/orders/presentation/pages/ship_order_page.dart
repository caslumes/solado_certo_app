import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/seller_order_detail_cubit.dart';

/// "Informar envio" (RF-021, UC-009): the carrier and the tracking code. An
/// invalid or repeated code keeps the form open with the error; any other
/// failure goes back to the order, which shows it.
class ShipOrderPage extends StatefulWidget {
  const ShipOrderPage({super.key, required this.carrier});

  /// Suggested from the shipping option the buyer chose.
  final String carrier;

  static Route<bool> route(SellerOrderDetailCubit cubit, {String? carrier}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ShipOrderPage(carrier: carrier ?? ''),
      ),
    );
  }

  @override
  State<ShipOrderPage> createState() => _ShipOrderPageState();
}

class _ShipOrderPageState extends State<ShipOrderPage> {
  final _formKey = GlobalKey<FormState>();
  late final _carrier = TextEditingController(text: widget.carrier);
  final _code = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _carrier.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _codeError = null);
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final failure = await context.read<SellerOrderDetailCubit>().ship(
      carrier: _carrier.text.trim(),
      trackingCode: FieldValidators.trackingCode(_code.text),
    );
    if (!mounted) return;
    if (failure is InvalidTrackingCodeFailure ||
        failure is TrackingCodeInUseFailure) {
      setState(() => _codeError = failure!.message);
      return;
    }
    navigator.pop(failure == null);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final working = context.select<SellerOrderDetailCubit, bool>(
      (cubit) => switch (cubit.state) {
        SellerOrderDetailLoaded(:final working) => working,
        _ => false,
      },
    );

    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          'Informar envio'.toUpperCase(),
          style: textTheme.bodyMedium,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Depois de postar o pedido, informe a transportadora e o código '
              'de rastreio. O comprador é avisado e passa a acompanhar a '
              'entrega.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ShoeTextFormField(
              labelText: 'Transportadora',
              hintText: 'Ex.: Correios',
              controller: _carrier,
              textCapitalization: TextCapitalization.words,
              validator: FieldValidators.combine([
                FieldValidators.required,
                FieldValidators.maxLength(80),
              ]),
              onChanged: (_) => setState(() => _codeError = null),
            ),
            const SizedBox(height: 16),
            ShoeTextFormField(
              labelText: 'Código de rastreio',
              hintText: 'Ex.: AA123456789BR',
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  FieldValidators.trackingCodeFor(_carrier.text)(value),
              forceErrorText: _codeError,
              onChanged: (_) {
                if (_codeError != null) setState(() => _codeError = null);
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ShoeTextButton(
            onPressed: working ? null : _submit,
            text: 'Confirmar envio',
          ),
        ),
      ),
    );
  }
}
