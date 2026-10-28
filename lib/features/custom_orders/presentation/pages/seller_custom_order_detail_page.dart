import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';
import 'package:solado_certo_app/features/custom_orders/domain/usecases/custom_order_use_cases.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/bloc/seller_custom_order_detail_cubit.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_decision_dialogs.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_sections.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/components/custom_order_status_chip.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/custom_order_detail_page.dart';
import 'package:solado_certo_app/features/custom_orders/presentation/pages/fitting_report_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/document_page.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/seller_order_detail_page.dart';

class SellerCustomOrderDetailPage extends StatelessWidget {
  const SellerCustomOrderDetailPage({
    super.key,
    this.onChanged,
    this.openDocument = _openDocument,
    this.openOrder = _openOrder,
    this.openReport = _openReport,
  });

  final ValueChanged<CustomOrderEntity>? onChanged;
  final void Function(BuildContext context, String url, String title)
  openDocument;
  final Future<void> Function(BuildContext context, String orderId) openOrder;
  final Future<void> Function(
    BuildContext context,
    SellerCustomOrderDetailCubit cubit,
  )
  openReport;

  static void _openDocument(BuildContext context, String url, String title) =>
      Navigator.of(context).push(DocumentPage.route(url, title: title));

  static Future<void> _openOrder(BuildContext context, String orderId) =>
      Navigator.of(context).push(SellerOrderDetailPage.route(orderId));

  static Future<void> _openReport(
    BuildContext context,
    SellerCustomOrderDetailCubit cubit,
  ) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FittingReportPage(submit: cubit.sendReport),
    ),
  );

  static Route<void> route(
    String requestId, {
    ValueChanged<CustomOrderEntity>? onChanged,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SellerCustomOrderDetailCubit(
          getCustomOrderUseCase: getIt<GetSellerCustomOrderUseCase>(),
          reviewUseCase: getIt<ReviewCustomOrderUseCase>(),
          acceptUseCase: getIt<AcceptCustomOrderUseCase>(),
          rejectUseCase: getIt<RejectCustomOrderUseCase>(),
          requestInfoUseCase: getIt<RequestCustomOrderInfoUseCase>(),
          sendReportUseCase: getIt<SendFittingReportUseCase>(),
          requestId: requestId,
        )..load(),
        child: SellerCustomOrderDetailPage(onChanged: onChanged),
      ),
    );
  }

  Future<void> _accept(BuildContext context) {
    final cubit = context.read<SellerCustomOrderDetailCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => AcceptCustomOrderDialog(submit: cubit.accept),
    );
  }

  Future<void> _requestInfo(BuildContext context) {
    final cubit = context.read<SellerCustomOrderDetailCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) =>
          CustomOrderReasonDialog.requestInfo(submit: cubit.requestInfo),
    );
  }

  Future<void> _reject(BuildContext context) {
    final cubit = context.read<SellerCustomOrderDetailCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => CustomOrderReasonDialog.reject(submit: cubit.reject),
    );
  }

  Future<void> _reloadAfter(
    BuildContext context,
    Future<void> Function() open,
  ) async {
    final cubit = context.read<SellerCustomOrderDetailCubit>();
    await open();
    cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SellerCustomOrderDetailCubit, CustomOrderDetailState>(
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
          CustomOrderDetailLoaded(:final detail) => _Detail(
            detail: detail,
            onViewDocument: (url, title) => openDocument(context, url, title),
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
              when _hasActions(detail) =>
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8.0,
                  children: [
                    if (detail.can(CustomOrderAction.report))
                      ShoeTextButton(
                        onPressed: working
                            ? null
                            : () => openReport(
                                context,
                                context.read<SellerCustomOrderDetailCubit>(),
                              ),
                        text: 'Enviar laudo',
                      ),
                    if (detail.can(CustomOrderAction.accept))
                      ShoeTextButton(
                        onPressed: working ? null : () => _accept(context),
                        text: 'Aceitar com preço',
                      ),
                    if (detail.can(CustomOrderAction.review) ||
                        detail.can(CustomOrderAction.requestInfo))
                      Row(
                        spacing: 8.0,
                        children: [
                          if (detail.can(CustomOrderAction.review))
                            Expanded(
                              child: TextButton(
                                onPressed: working
                                    ? null
                                    : context
                                          .read<SellerCustomOrderDetailCubit>()
                                          .review,
                                child: const Text('Iniciar análise'),
                              ),
                            ),
                          if (detail.can(CustomOrderAction.requestInfo))
                            Expanded(
                              child: TextButton(
                                onPressed: working
                                    ? null
                                    : () => _requestInfo(context),
                                child: const Text('Pedir informações'),
                              ),
                            ),
                        ],
                      ),
                    if (detail.can(CustomOrderAction.reject))
                      TextButton(
                        onPressed: working ? null : () => _reject(context),
                        child: const Text('Recusar solicitação'),
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

  static bool _hasActions(CustomOrderDetailEntity detail) => [
    CustomOrderAction.report,
    CustomOrderAction.accept,
    CustomOrderAction.review,
    CustomOrderAction.requestInfo,
    CustomOrderAction.reject,
  ].any(detail.can);

  static void _signOut(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AuthBloc>().add(SignOutEvent());
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.detail,
    required this.onViewDocument,
    required this.onOpenOrder,
  });

  final CustomOrderDetailEntity detail;
  final void Function(String url, String title) onViewDocument;
  final ValueChanged<String> onOpenOrder;

  String _hint() {
    final request = detail.request;
    return switch (request.status) {
      CustomOrderStatus.requested =>
        'Confira as medidas e responda: aceite com o preço, peça mais '
            'informações ou recuse. "Iniciar análise" avisa o comprador que '
            'você está analisando.',
      CustomOrderStatus.underReview =>
        'Aceite com o preço, peça mais informações ou recuse.',
      CustomOrderStatus.needsInfo => switch (CustomOrderDetailPage.lastQuestion(
        detail,
      )) {
        final question? => 'Aguardando a resposta do comprador: $question',
        null => 'Aguardando a resposta do comprador.',
      },
      CustomOrderStatus.approved when detail.orderId != null =>
        'O comprador confirmou o pedido. A produção começa depois do '
            'pagamento.',
      CustomOrderStatus.approved => switch (request.quotedPrice) {
        final price? =>
          'Você aceitou por ${formatCurrency(price)}. Aguardando o comprador '
              'confirmar e pagar.',
        null => 'Aguardando o comprador confirmar e pagar.',
      },
      CustomOrderStatus.rejected => switch (detail.rejectionReason) {
        final reason? => 'Você recusou a solicitação: $reason',
        null => 'Você recusou a solicitação.',
      },
      CustomOrderStatus.inProduction =>
        'Pagamento aprovado. Produza o item e envie o laudo com as '
            'instruções de adaptação; o pedido só pode ser enviado depois '
            'disso.',
      CustomOrderStatus.completed =>
        'Laudo enviado ao comprador. Envie o pedido pela tela do pedido.',
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

    return RefreshIndicator(
      onRefresh: () => context.read<SellerCustomOrderDetailCubit>().load(),
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
                      'Pedido por ${request.buyerName}',
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
          const SizedBox(height: 12),
          Text(_hint(), style: textTheme.bodySmall),
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
            Text('Observações do comprador', style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(notes, style: textTheme.bodyLarge),
          ],
          if (photoUrl != null) ...[
            const SizedBox(height: 12),
            Text('Foto do pé', style: textTheme.bodyMedium),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => onViewDocument(photoUrl, 'Foto do pé'),
                child: const Text('Ver foto'),
              ),
            ),
          ],
          const Divider(height: 32),
          Text('Histórico', style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (final (index, change) in detail.history.indexed)
            CustomOrderHistoryEntry(
              change: change,
              isLatest: index == detail.history.length - 1,
              seller: true,
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
              onPressed: () =>
                  context.read<SellerCustomOrderDetailCubit>().load(),
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
