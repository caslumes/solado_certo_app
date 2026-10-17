import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/checkout/presentation/components/checkout_steps.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_amounts.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment_request.dart';
import 'package:solado_certo_app/features/payments/domain/enum/payment_method.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';
import 'package:solado_certo_app/features/payments/presentation/bloc/payment_cubit.dart';
import 'package:solado_certo_app/features/payments/presentation/components/payment_views.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pays one order with Pix, boleto or card (RF-016, UC-006 step 6), then shows
/// the result (RF-018). The route answers true once the order is paid.
class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.order,
    this.position,
    this.openUrl = _openExternally,
  });

  final OrderEntity order;

  /// The order's place in a checkout with several sellers, e.g. `1 de 2`.
  final String? position;
  final Future<bool> Function(Uri url) openUrl;

  static Future<bool> _openExternally(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  static Route<bool> route(OrderEntity order, {String? position}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => PaymentCubit(
          order: order,
          getProfileUseCase: getIt<GetProfileUseCase>(),
          getPaymentsUseCase: getIt<GetPaymentsUseCase>(),
          createPaymentUseCase: getIt<CreatePaymentUseCase>(),
        )..load(),
        child: PaymentPage(order: order, position: position),
      ),
    );
  }

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _taxId = TextEditingController();
  final _cardNumber = TextEditingController();
  final _holderName = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in [
      _taxId,
      _cardNumber,
      _holderName,
      _expiry,
      _cvv,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Back from the bank's app or the boleto: check whether it was paid.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PaymentCubit>().refresh();
    }
  }

  void _pay() {
    final cubit = context.read<PaymentCubit>();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    CardDetails? card;
    if (cubit.state.method == PaymentMethod.creditCard) {
      final expiry = FieldValidators.parseCardExpiry(_expiry.text)!;
      card = CardDetails(
        holderName: _holderName.text.trim(),
        number: FieldValidators.digits(_cardNumber.text),
        expiryMonth: expiry.month,
        expiryYear: expiry.year,
        cvv: _cvv.text.trim(),
      );
    }
    cubit.pay(taxId: FieldValidators.digits(_taxId.text), card: card);
  }

  Future<void> _openBoleto(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await widget.openUrl(Uri.parse(url));
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o boleto.')),
        );
    }
  }

  void _onStateChanged(BuildContext context, PaymentState state) {
    final failure = state.failure;
    if (failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    if (state.stage == PaymentStage.loadFailure ||
        state.stage == PaymentStage.closed) {
      return;
    }
    final message = failure?.message ?? state.notice;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: failure is GatewayUnavailableFailure
              ? SnackBarAction(label: 'Tentar novamente', onPressed: _pay)
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<PaymentCubit, PaymentState>(
      listenWhen: (_, current) =>
          current.failure != null || current.notice != null,
      listener: _onStateChanged,
      builder: (context, state) {
        final approved = state.stage == PaymentStage.approved;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(approved);
          },
          child: Scaffold(
            appBar: AppBar(
              iconTheme: Theme.of(context).iconTheme,
              title: Text(
                (approved ? 'Pagamento aprovado' : 'Pagamento').toUpperCase(),
                style: textTheme.bodyMedium,
              ),
            ),
            body: switch (state.stage) {
              PaymentStage.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              PaymentStage.loadFailure => _Message(
                message: state.failure!.message,
                action: 'Tentar novamente',
                onPressed: context.read<PaymentCubit>().load,
              ),
              PaymentStage.closed => _Message(
                message: state.failure?.message ?? '',
                action: 'Voltar',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              PaymentStage.choosing => _buildChoice(context, state),
              PaymentStage.waiting => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  PaymentOrderHeader(
                    order: widget.order,
                    position: widget.position,
                  ),
                  const SizedBox(height: 24),
                  if (state.payment?.method == PaymentMethod.boleto)
                    BoletoPaymentView(
                      payment: state.payment!,
                      onOpen: _openBoleto,
                    )
                  else
                    PixPaymentView(payment: state.payment!),
                ],
              ),
              PaymentStage.approved => PaymentApprovedView(
                order: widget.order,
                payment: state.payment!,
              ),
            },
            bottomNavigationBar: _buildActions(context, state),
          ),
        );
      },
    );
  }

  Widget _buildChoice(BuildContext context, PaymentState state) {
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<PaymentCubit>();
    final refused = state.payment;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PaymentOrderHeader(
              order: widget.order,
              position: widget.position,
            ),
          ),
          if (refused != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: CheckoutWarning(
                text:
                    '${refused.failureMessage ?? 'O pagamento não foi aprovado.'}'
                    ' Tente outro cartão ou escolha outra forma de pagamento.',
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Como você quer pagar?', style: textTheme.bodyMedium),
          ),
          for (final method in PaymentMethod.values)
            CheckoutChoiceTile(
              key: ValueKey(method),
              selected: method == state.method,
              title: method.label,
              subtitle: paymentMethodHint(method),
              trailing: formatCurrency(widget.order.amountFor(method)),
              onTap: state.submitting ? null : () => cubit.selectMethod(method),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16.0,
              children: [
                if (state.needsTaxId) ...[
                  const SizedBox(),
                  ShoeTextFormField(
                    labelText: 'CPF',
                    hintText: '000.000.000-00',
                    controller: _taxId,
                    keyboardType: TextInputType.number,
                    validator: FieldValidators.cpf,
                  ),
                  Text(
                    'O CPF é exigido para emitir a cobrança. Pedimos só '
                    'uma vez.',
                    style: textTheme.bodySmall,
                  ),
                ],
                if (state.method == PaymentMethod.creditCard) ...[
                  const SizedBox(),
                  ShoeTextFormField(
                    labelText: 'Número do cartão',
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.creditCardNumber],
                    validator: FieldValidators.cardNumber,
                  ),
                  ShoeTextFormField(
                    labelText: 'Nome impresso no cartão',
                    controller: _holderName,
                    textCapitalization: TextCapitalization.characters,
                    autofillHints: const [AutofillHints.creditCardName],
                    validator: FieldValidators.required,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16.0,
                    children: [
                      Expanded(
                        child: ShoeTextFormField(
                          labelText: 'Validade',
                          hintText: 'MM/AA',
                          controller: _expiry,
                          keyboardType: TextInputType.datetime,
                          validator: FieldValidators.cardExpiry(),
                        ),
                      ),
                      Expanded(
                        child: ShoeTextFormField(
                          labelText: 'CVV',
                          controller: _cvv,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: FieldValidators.cvv,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Os dados do cartão são enviados à operadora e não ficam '
                    'salvos.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActions(BuildContext context, PaymentState state) {
    final cubit = context.read<PaymentCubit>();
    final List<Widget> actions = switch (state.stage) {
      PaymentStage.choosing => [
        ShoeTextButton(
          isLoading: state.submitting,
          onPressed: _pay,
          text: 'Pagar ${formatCurrency(widget.order.amountFor(state.method))}',
        ),
      ],
      PaymentStage.waiting => [
        ShoeTextButton(
          isLoading: state.refreshing,
          onPressed: () => cubit.refresh(manual: true),
          text: 'Já paguei',
        ),
        TextButton(
          onPressed: cubit.chooseAnotherMethod,
          child: const Text('Escolher outra forma de pagamento'),
        ),
      ],
      PaymentStage.approved => [
        ShoeTextButton(
          onPressed: () => Navigator.of(context).pop(true),
          text: 'Concluir',
        ),
      ],
      _ => const [],
    };
    if (actions.isEmpty) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8.0,
          children: actions,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(onPressed: onPressed, text: action),
          ],
        ),
      ),
    );
  }
}
