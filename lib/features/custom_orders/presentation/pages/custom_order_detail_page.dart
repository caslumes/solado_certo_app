import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/cancel_custom_order_dialog.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_consent_dialog.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_sections.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_status_chip.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/foot_photo_source_sheet.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_checkout_page.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_complement_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/document_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/grant_custom_order_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_custom_order_consent_use_case.dart';

class CustomOrderDetailPage extends StatelessWidget {
  const CustomOrderDetailPage({
    super.key,
    this.onChanged,
    this.askConsent = askCustomOrderConsent,
    this.pickPhoto = pickFootPhoto,
    this.openDocument = _openDocument,
    this.openOrder = _openOrder,
    this.openCheckout = _openCheckout,
  });

  final ValueChanged<CustomOrderEntity>? onChanged;
  final Future<bool> Function(BuildContext context) askConsent;
  final Future<UploadFile?> Function(BuildContext context) pickPhoto;
  final void Function(BuildContext context, String url, String title)
  openDocument;
  final Future<void> Function(BuildContext context, String orderId) openOrder;
  final Future<void> Function(BuildContext context, CustomOrderEntity request)
  openCheckout;

  static void _openDocument(BuildContext context, String url, String title) =>
      Navigator.of(context).push(DocumentPage.route(url, title: title));

  static Future<void> _openOrder(BuildContext context, String orderId) =>
      Navigator.of(context).push(OrderDetailPage.route(orderId));

  static Future<void> _openCheckout(
    BuildContext context,
    CustomOrderEntity request,
  ) => Navigator.of(context).push(CustomOrderCheckoutPage.route(request));

  static Route<void> route(
    String requestId, {
    ValueChanged<CustomOrderEntity>? onChanged,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => CustomOrderDetailCubit(
          getCustomOrderUseCase: getIt<GetCustomOrderUseCase>(),
          complementUseCase: getIt<ComplementCustomOrderUseCase>(),
          cancelUseCase: getIt<CancelCustomOrderUseCase>(),
          sendFootPhotoUseCase: getIt<SendFootPhotoUseCase>(),
          hasConsentUseCase: getIt<HasCustomOrderConsentUseCase>(),
          grantConsentUseCase: getIt<GrantCustomOrderConsentUseCase>(),
          requestId: requestId,
        )..load(),
        child: CustomOrderDetailPage(onChanged: onChanged),
      ),
    );
  }

  static String? lastQuestion(CustomOrderDetailEntity detail) {
    for (final change in detail.history.reversed) {
      if (change.to == CustomOrderStatus.needsInfo) return change.reason;
    }
    return null;
  }

  Future<bool> _ensureConsent(BuildContext context) async {
    final cubit = context.read<CustomOrderDetailCubit>();
    final consented = await cubit.hasConsent();
    if (consented == null || !context.mounted) return false;
    if (consented) return true;
    if (!await askConsent(context)) return false;
    return cubit.grantConsent();
  }

  Future<void> _complement(
    BuildContext context,
    CustomOrderDetailEntity detail,
  ) async {
    final cubit = context.read<CustomOrderDetailCubit>();
    if (!await _ensureConsent(context) || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomOrderComplementPage(
          detail: detail,
          question: lastQuestion(detail),
          submit: cubit.complement,
        ),
      ),
    );
  }

  Future<void> _sendPhoto(BuildContext context) async {
    final cubit = context.read<CustomOrderDetailCubit>();
    if (!await _ensureConsent(context) || !context.mounted) return;
    final photo = await pickPhoto(context);
    if (photo == null) return;
    await cubit.sendPhoto(photo);
  }

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<CustomOrderDetailCubit>();
    final answer = await CancelCustomOrderDialog.show(context);
    if (answer == null) return;
    await cubit.cancel(reason: answer.reason);
  }

  Future<void> _reloadAfter(
    BuildContext context,
    Future<void> Function() open,
  ) async {
    final cubit = context.read<CustomOrderDetailCubit>();
    await open();
    cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<CustomOrderDetailCubit, CustomOrderDetailState>(
      listener: (context, state) {
        if (state is CustomOrderDetailLoadFailure &&
            state.failure is UnauthorizedFailure) {
          return _signOut(context);
        }
        if (state is! CustomOrderDetailLoaded || state.working) return;
        onChanged?.call(state.detail.request);
        final failure = state.failure;
        if (failure is UnauthorizedFailure) return _signOut(context);
        final message = switch (failure) {
          OrderStatusChangedFailure() =>
            'A situação desta solicitação mudou. Confira e tente de novo.',
          final failure? => failure.message,
          null => state.notice,
        };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          title: Text('Sob medida'.toUpperCase(), style: textTheme.bodyMedium),
        ),
        body: switch (state) {
          CustomOrderDetailLoaded(:final detail, :final working) => _Detail(
            detail: detail,
            onViewDocument: (url, title) => openDocument(context, url, title),
            onSendPhoto: working ? null : () => _sendPhoto(context),
            onOpenOrder: (orderId) =>
                _reloadAfter(context, () => openOrder(context, orderId)),
          ),
          CustomOrderDetailLoadFailure(:final failure) => _LoadError(
            failure: failure,
          ),
          CustomOrderDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        },
        bottomNavigationBar: switch (state) {
          CustomOrderDetailLoaded(:final detail, :final working)
              when _hasBottomActions(detail) =>
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8.0,
                  children: [
                    if (detail.can(CustomOrderAction.complement))
                      ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => _complement(context, detail),
                        text: 'Responder ao vendedor',
                      ),
                    if (detail.can(CustomOrderAction.checkout))
                      ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => _reloadAfter(
                                context,
                                () => openCheckout(context, detail.request),
                              ),
                        text: 'Confirmar e pagar',
                      ),
                    if (_awaitsPayment(detail))
                      ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => _reloadAfter(
                                context,
                                () => openOrder(context, detail.orderId!),
                              ),
                        text: 'Pagar pedido',
                      ),
                    if (detail.can(CustomOrderAction.cancel))
                      TextButton(
                        onPressed: working ? null : () => _cancel(context),
                        child: const Text('Cancelar solicitação'),
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

  static bool _awaitsPayment(CustomOrderDetailEntity detail) =>
      detail.request.status == CustomOrderStatus.approved &&
      detail.orderId != null;

  static bool _hasBottomActions(CustomOrderDetailEntity detail) =>
      detail.can(CustomOrderAction.complement) ||
      detail.can(CustomOrderAction.checkout) ||
      detail.can(CustomOrderAction.cancel) ||
      _awaitsPayment(detail);

  static void _signOut(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AuthBloc>().add(SignOutEvent());
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.detail,
    required this.onViewDocument,
    required this.onSendPhoto,
    required this.onOpenOrder,
  });

  final CustomOrderDetailEntity detail;
  final void Function(String url, String title) onViewDocument;
  final VoidCallback? onSendPhoto;
  final ValueChanged<String> onOpenOrder;

  String? _hint() {
    final request = detail.request;
    return switch (request.status) {
      CustomOrderStatus.requested =>
        'O vendedor vai analisar suas medidas e responder. Você é avisado a '
            'cada mudança.',
      CustomOrderStatus.underReview =>
        'O vendedor está analisando sua solicitação.',
      CustomOrderStatus.needsInfo => switch (CustomOrderDetailPage.lastQuestion(
        detail,
      )) {
        final question? => 'O vendedor precisa de mais informações: $question',
        null => 'O vendedor precisa de mais informações.',
      },
      CustomOrderStatus.approved when detail.orderId != null =>
        'Pedido criado. Pague para a produção começar.',
      CustomOrderStatus.approved => switch (request.quotedPrice) {
        final price? =>
          'O vendedor aceitou fazer o item por ${formatCurrency(price)}. '
              'Confirme e pague para a produção começar.',
        null => 'O vendedor aceitou. Confirme e pague para a produção começar.',
      },
      CustomOrderStatus.rejected => switch (detail.rejectionReason) {
        final reason? => 'O vendedor recusou a solicitação: $reason',
        null => 'O vendedor recusou a solicitação.',
      },
      CustomOrderStatus.inProduction =>
        'Pagamento aprovado. O vendedor está produzindo o item e vai enviar o '
            'laudo e as instruções de adaptação junto com ele.',
      CustomOrderStatus.completed =>
        'Leia o laudo e as instruções de adaptação antes de começar a usar.',
      CustomOrderStatus.cancelled => 'Esta solicitação foi cancelada.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final request = detail.request;
    final notes = detail.technicalNotes;
    final report = detail.fittingReport;
    final instructions = detail.adaptationInstructions;
    final photoUrl = detail.footPhotoUrl;
    final orderId = detail.orderId;
    final canSendPhoto = detail.can(CustomOrderAction.sendPhoto);

    return RefreshIndicator(
      onRefresh: () => context.read<CustomOrderDetailCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12.0,
            children: [
              SizedBox.square(
                dimension: 64,
                child: ProductImage(url: request.coverUrl),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4.0,
                  children: [
                    Text(
                      request.advertisementTitle,
                      style: textTheme.bodyMedium,
                    ),
                    Text(
                      'Vendido por ${request.sellerName}',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'Solicitada em ${formatDateTime(request.createdAt)}',
                      style: textTheme.bodySmall,
                    ),
                    CustomOrderStatusChip(status: request.status),
                  ],
                ),
              ),
            ],
          ),
          if (_hint() case final hint?) ...[
            const SizedBox(height: 12),
            Text(hint, style: textTheme.bodySmall),
          ],
          if (request.quotedPrice case final price?) ...[
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text('Preço combinado', style: textTheme.bodyLarge),
                ),
                Text(formatCurrency(price), style: textTheme.bodyMedium),
              ],
            ),
            Text(
              'O frete é escolhido ao confirmar.',
              style: textTheme.bodySmall,
            ),
          ],
          if (orderId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => onOpenOrder(orderId),
                child: const Text('Ver pedido'),
              ),
            ),
          if (report != null || instructions != null) ...[
            const Divider(height: 32),
            Text('Laudo e adaptação', style: textTheme.bodyMedium),
            if (instructions != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                color: AppColors.warningBackgroundColor,
                child: Text(instructions, style: textTheme.bodyLarge),
              ),
            ],
            if (report != null) ...[
              const SizedBox(height: 4),
              Text(
                'Laudo enviado em ${formatDateTime(report.createdAt)}',
                style: textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => onViewDocument(report.url, 'Laudo'),
                  child: const Text('Ver laudo'),
                ),
              ),
            ],
          ],
          const Divider(height: 32),
          Text('Medidas', style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          MeasurementsSummary(measurements: detail.measurements),
          if (notes != null) ...[
            const SizedBox(height: 12),
            Text('Observações', style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(notes, style: textTheme.bodyLarge),
          ],
          if (photoUrl != null || canSendPhoto) ...[
            const SizedBox(height: 12),
            Text('Foto do pé', style: textTheme.bodyMedium),
            Wrap(
              spacing: 16.0,
              children: [
                if (photoUrl != null)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => onViewDocument(photoUrl, 'Foto do pé'),
                    child: const Text('Ver foto'),
                  ),
                if (canSendPhoto)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: onSendPhoto,
                    child: Text(
                      photoUrl == null ? 'Enviar foto' : 'Trocar foto',
                    ),
                  ),
              ],
            ),
          ],
          const Divider(height: 32),
          Text('Histórico', style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (final (index, change) in detail.history.indexed)
            CustomOrderHistoryEntry(
              change: change,
              isLatest: index == detail.history.length - 1,
            ),
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
              failure is NotFoundFailure
                  ? 'Solicitação não encontrada.'
                  : failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ShoeTextButton(
              onPressed: () => context.read<CustomOrderDetailCubit>().load(),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
