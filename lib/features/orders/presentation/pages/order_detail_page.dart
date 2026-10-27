import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order_detail.dart';
import 'package:solado_certo_app/features/orders/domain/enum/order_status.dart';
import 'package:solado_certo_app/features/orders/domain/usecases/order_use_cases.dart';
import 'package:solado_certo_app/features/orders/presentation/bloc/order_detail_cubit.dart';
import 'package:solado_certo_app/features/orders/presentation/components/amount_row.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_sections.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_status_chip.dart';
import 'package:solado_certo_app/features/orders/presentation/components/order_texts.dart';
import 'package:solado_certo_app/features/orders/presentation/components/prescription_consent_dialog.dart';
import 'package:solado_certo_app/features/orders/presentation/components/prescription_section.dart';
import 'package:solado_certo_app/features/orders/presentation/components/prescription_source_sheet.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/document_page.dart';
import 'package:solado_certo_app/features/payments/domain/entities/payment.dart';
import 'package:solado_certo_app/features/payments/domain/usecases/payment_use_cases.dart';
import 'package:solado_certo_app/features/payments/presentation/pages/payment_page.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_prescription_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_prescription_consent_use_case.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/item_review_summary.dart';
import 'package:solado_certo_app/features/reviews/presentation/pages/review_page.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    super.key,
    this.onChanged,
    this.openUrl = _openExternally,
    this.askConsent = askPrescriptionConsent,
    this.pickFile = pickPrescription,
    this.openDocument = _openDocument,
  });

  final ValueChanged<OrderEntity>? onChanged;

  final Future<bool> Function(Uri url) openUrl;
  final Future<bool> Function(BuildContext context) askConsent;
  final Future<UploadFile?> Function(BuildContext context) pickFile;
  final void Function(BuildContext context, String url) openDocument;

  static void _openDocument(BuildContext context, String url) =>
      Navigator.of(context).push(DocumentPage.route(url, title: 'Receita'));

  static Future<bool> _openExternally(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  static Route<void> route(
    String orderId, {
    ValueChanged<OrderEntity>? onChanged,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => OrderDetailCubit(
          getOrderUseCase: getIt<GetOrderUseCase>(),
          cancelOrderUseCase: getIt<CancelOrderUseCase>(),
          confirmDeliveryUseCase: getIt<ConfirmDeliveryUseCase>(),
          getPaymentsUseCase: getIt<GetPaymentsUseCase>(),
          uploadPrescriptionUseCase: getIt<UploadPrescriptionUseCase>(),
          hasPrescriptionConsentUseCase: getIt<HasPrescriptionConsentUseCase>(),
          grantPrescriptionConsentUseCase:
              getIt<GrantPrescriptionConsentUseCase>(),
          orderId: orderId,
        )..load(),
        child: OrderDetailPage(onChanged: onChanged),
      ),
    );
  }

  Future<void> _pay(BuildContext context, OrderEntity order) async {
    final cubit = context.read<OrderDetailCubit>();
    await Navigator.of(context).push(PaymentPage.route(order));
    cubit.load();
  }

  Future<void> _sendPrescription(
    BuildContext context,
    OrderItemEntity item,
  ) async {
    final cubit = context.read<OrderDetailCubit>();
    final consented = await cubit.hasPrescriptionConsent();
    if (consented == null || !context.mounted) return;
    if (!consented) {
      if (!await askConsent(context)) return;
      if (!await cubit.grantPrescriptionConsent()) return;
      if (!context.mounted) return;
    }
    final file = await pickFile(context);
    if (file == null) return;
    await cubit.uploadPrescription(item.id!, file);
  }

  Future<void> _confirmCancel(BuildContext context, OrderEntity order) async {
    final cubit = context.read<OrderDetailCubit>();
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar pedido?', style: textTheme.bodyMedium),
        content: Text(
          order.status == OrderStatus.paid
              ? 'O valor pago será estornado na mesma forma de pagamento. Os '
                    'produtos voltam a ficar à venda e o pedido não poderá ser '
                    'retomado.'
              : 'Os produtos voltam a ficar à venda e o pedido não poderá ser '
                    'retomado.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.cancel();
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recebeu o pedido?', style: textTheme.bodyMedium),
        content: Text(
          'Confirme só se todos os produtos chegaram. Depois você pode '
          'avaliá-los.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.confirmDelivery();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<OrderDetailCubit, OrderDetailState>(
      listener: (context, state) {
        if (state is OrderDetailLoadFailure &&
            state.failure is UnauthorizedFailure) {
          return _signOut(context);
        }
        if (state is! OrderDetailLoaded || state.working) return;
        onChanged?.call(state.detail.order);
        final failure = state.failure;
        if (failure is UnauthorizedFailure) return _signOut(context);
        final message = failure?.message ?? state.notice;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          title: Text('Pedido'.toUpperCase(), style: textTheme.bodyMedium),
        ),
        body: switch (state) {
          OrderDetailLoaded(:final detail, :final payments, :final working) =>
            _Detail(
              detail: detail,
              payments: payments,
              openUrl: openUrl,
              onSendPrescription: working
                  ? null
                  : (item) => _sendPrescription(context, item),
              onViewPrescription: (url) => openDocument(context, url),
            ),
          OrderDetailLoadFailure(:final failure) => _LoadError(
            failure: failure,
          ),
          OrderDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        },
        bottomNavigationBar: switch (state) {
          OrderDetailLoaded(:final detail, :final working)
              when detail.order.status == OrderStatus.awaitingPayment ||
                  detail.canCancel ||
                  detail.canConfirmDelivery =>
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8.0,
                  children: [
                    if (detail.order.status == OrderStatus.awaitingPayment &&
                        detail.order.itemsAwaitingPrescription.isNotEmpty)
                      Text(
                        'Envie a receita dos itens que exigem prescrição para '
                        'liberar o pagamento.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                    if (detail.order.status == OrderStatus.awaitingPayment)
                      ShoeTextButton(
                        onPressed:
                            working ||
                                detail
                                    .order
                                    .itemsAwaitingPrescription
                                    .isNotEmpty
                            ? null
                            : () => _pay(context, detail.order),
                        text: 'Pagar',
                      ),
                    if (detail.canConfirmDelivery)
                      ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => _confirmDelivery(context),
                        text: 'Recebi meu pedido',
                      ),
                    if (detail.canCancel)
                      TextButton(
                        onPressed: working
                            ? null
                            : () => _confirmCancel(context, detail.order),
                        child: const Text('Cancelar pedido'),
                      ),
                  ],
                ),
              ),
            ),
          _ => null,
        },
      ),
    );
  }

  static void _signOut(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AuthBloc>().add(SignOutEvent());
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.detail,
    required this.payments,
    required this.openUrl,
    required this.onSendPrescription,
    required this.onViewPrescription,
  });

  final OrderDetailEntity detail;
  final List<PaymentEntity> payments;
  final Future<bool> Function(Uri url) openUrl;
  final ValueChanged<OrderItemEntity>? onSendPrescription;
  final ValueChanged<String> onViewPrescription;

  Future<void> _review(BuildContext context, OrderItemEntity item) async {
    final cubit = context.read<OrderDetailCubit>();
    final reviewed = await Navigator.of(context).push(
      ReviewPage.route(
        orderId: detail.order.id,
        item: item,
        sellerName: detail.order.sellerName,
      ),
    );
    if (reviewed == true) cubit.load();
  }

  Widget? _itemFooter(BuildContext context, OrderItemEntity item) {
    final review = _reviewFooter(context, item);
    if (!item.prescriptionRequired) return review;
    final send = onSendPrescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrescriptionSection(
          item: item,
          onView: switch (item.prescription) {
            final prescription? => () => onViewPrescription(prescription.url),
            null => null,
          },
          actions: [
            if (item.canUploadPrescription && item.id != null)
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: send == null ? null : () => send(item),
                child: Text(
                  item.prescription == null
                      ? 'Enviar receita'
                      : 'Enviar outra receita',
                ),
              ),
          ],
        ),
        ?review,
      ],
    );
  }

  Widget? _reviewFooter(BuildContext context, OrderItemEntity item) {
    if (item.review case final review?) {
      return ItemReviewSummary(review: review, title: 'Sua avaliação');
    }
    if (item.id == null || detail.order.status != OrderStatus.delivered) {
      return null;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () => _review(context, item),
        child: const Text('Avaliar'),
      ),
    );
  }

  static String? _hint(OrderDetailEntity detail) =>
      switch (detail.order.status) {
        OrderStatus.awaitingPayment
            when detail.order.itemsAwaitingPrescription.isNotEmpty =>
          'Os produtos ficam reservados para você até o pagamento. Antes de '
              'pagar, envie a receita dos itens que exigem prescrição.',
        OrderStatus.awaitingPayment =>
          'Os produtos ficam reservados para você até o pagamento.',
        OrderStatus.paid || OrderStatus.processing
            when detail.order.itemsAwaitingPrescription.isNotEmpty =>
          'O vendedor recusou a receita de um item. Envie outra para que o '
              'pedido possa ser enviado.',
        OrderStatus.shipped =>
          'Quando o pedido chegar, confirme o recebimento para avaliar os '
              'produtos.',
        OrderStatus.delivered
            when detail.order.items.any((item) => item.review == null) =>
          'Conte como foi a adaptação: avalie cada produto.',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final order = detail.order;
    final shipment = detail.shipment;

    return RefreshIndicator(
      onRefresh: () => context.read<OrderDetailCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Pedido ${order.number}', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Feito em ${formatDateTime(order.createdAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OrderStatusChip(status: order.status),
          ),
          if (_hint(detail) case final hint?) ...[
            const SizedBox(height: 12),
            Text(hint, style: textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Text('Vendido por ${order.sellerName}', style: textTheme.bodyMedium),
          for (final item in order.items)
            OrderItemRow(item: item, footer: _itemFooter(context, item)),
          const Divider(height: 32),
          Text('Entrega', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(order.address.receiver, style: textTheme.bodyLarge),
          Text(
            formatShippingAddress(order.address),
            style: textTheme.bodySmall,
          ),
          if (shipment != null) ...[
            const Divider(height: 32),
            ShipmentSection(shipment: shipment, openUrl: openUrl),
          ],
          const Divider(height: 32),
          AmountRow(label: 'Subtotal', value: order.subtotal),
          AmountRow(label: 'Frete', value: order.shippingTotal),
          AmountRow(
            label: 'Desconto',
            value: order.discountTotal,
            isDiscount: true,
          ),
          const Divider(),
          AmountRow(label: 'Total', value: order.total, emphasized: true),
          if (payments.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Pagamento', style: textTheme.bodyMedium),
            for (final payment in payments)
              _PaymentRow(
                payment: payment,
                orderCancelled: order.status == OrderStatus.cancelled,
                openUrl: openUrl,
              ),
          ],
          const Divider(height: 32),
          Text('Histórico', style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (final (index, change) in detail.history.indexed)
            OrderHistoryEntry(
              change: change,
              isLatest: index == detail.history.length - 1,
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.orderCancelled,
    required this.openUrl,
  });

  final PaymentEntity payment;
  final bool orderCancelled;
  final Future<bool> Function(Uri url) openUrl;

  Future<void> _openRefund(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await openUrl(Uri.parse(url));
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir a página.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final method = switch (payment.card) {
      final card? => '${payment.method.label} final ${card.last4}',
      null => payment.method.label,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method, style: textTheme.bodyLarge),
                Text(
                  '${payment.statusLabel(orderCancelled: orderCancelled)} · '
                  '${formatDateTime(payment.capturedAt ?? payment.createdAt)}',
                  style: textTheme.bodySmall,
                ),
                if (payment.refundUrl case final url?
                    when payment.awaitsRefundAccount) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Para estornar um boleto, informe a conta bancária que '
                    'vai receber o valor.',
                    style: textTheme.bodySmall,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _openRefund(context, url),
                    child: const Text('Informar conta para estorno'),
                  ),
                ],
              ],
            ),
          ),
          Text(formatCurrency(payment.amount), style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.failure});

  final Failure failure;

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
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(
              onPressed: () => context.read<OrderDetailCubit>().load(),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
