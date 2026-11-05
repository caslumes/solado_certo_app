import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/core/formatting/formatters.dart';
import 'package:solado_certo_app/core/presentation/components/reason_dialog.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/orders/presentation/components/prescription_source_sheet.dart';
import 'package:solado_certo_app/features/orders/presentation/pages/document_page.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_detail_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/components/support_ticket_status_chip.dart';

class SupportTicketDetailPage extends StatefulWidget {
  const SupportTicketDetailPage({
    super.key,
    this.admin = false,
    this.pickFile = _pickAttachment,
    this.openAttachment = _openAttachment,
  });

  final bool admin;
  final Future<UploadFile?> Function(BuildContext context) pickFile;
  final void Function(BuildContext context, String url) openAttachment;

  static Future<UploadFile?> _pickAttachment(BuildContext context) =>
      pickDocumentFile(
        context,
        title: 'Anexar arquivo',
        hint: 'PDF, JPEG ou PNG de até 5 MB.',
      );

  static void _openAttachment(BuildContext context, String url) {
    Navigator.of(context).push(DocumentPage.route(url, title: 'Anexo'));
  }

  static Route<void> route(String ticketId, {bool admin = false}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SupportTicketDetailCubit(
          getTicketUseCase: getIt<GetSupportTicketUseCase>(),
          sendMessageUseCase: getIt<SendSupportMessageUseCase>(),
          assignTicketUseCase: admin
              ? getIt<AssignSupportTicketUseCase>()
              : null,
          closeTicketUseCase: admin ? getIt<CloseSupportTicketUseCase>() : null,
          ticketId: ticketId,
        )..load(),
        child: SupportTicketDetailPage(admin: admin),
      ),
    );
  }

  @override
  State<SupportTicketDetailPage> createState() =>
      _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState extends State<SupportTicketDetailPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _signOut() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AuthBloc>().add(SignOutEvent());
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _assign() async {
    final assigned = await context.read<SupportTicketDetailCubit>().assign();
    if (assigned && mounted) _notify('Você é o responsável por este chamado.');
  }

  Future<void> _close() async {
    final cubit = context.read<SupportTicketDetailCubit>();
    final resolution = await ReasonDialog.show(
      context,
      title: 'Encerrar chamado',
      message:
          'A decisão é enviada às partes e o chamado deixa de receber '
          'mensagens.',
      label: 'Decisão',
      confirmText: 'Encerrar',
      minLength: 10,
      maxLength: 2000,
    );
    if (resolution == null || !mounted) return;
    final closed = await cubit.resolve(resolution);
    if (closed && mounted) _notify('Chamado resolvido.');
  }

  List<Widget> _adminActions(SupportTicketDetailState state) {
    if (!widget.admin || state is! SupportTicketDetailLoaded) return const [];
    final ticket = state.detail.ticket;
    if (!ticket.status.isActive) return const [];
    return [
      if (!ticket.assignedToMe)
        IconButton(
          tooltip: 'Assumir chamado',
          onPressed: state.sending ? null : _assign,
          icon: const Icon(Icons.assignment_ind_outlined),
        ),
      IconButton(
        tooltip: 'Encerrar chamado',
        onPressed: state.sending ? null : _close,
        icon: const Icon(Icons.task_alt),
      ),
    ];
  }

  void _onStateChanged(BuildContext context, SupportTicketDetailState state) {
    if (state is SupportTicketDetailLoadFailure &&
        state.failure is UnauthorizedFailure) {
      return _signOut();
    }
    if (state is! SupportTicketDetailLoaded || state.sending) return;
    final failure = state.failure;
    if (failure == null) return _scrollToEnd();
    if (failure is UnauthorizedFailure) return _signOut();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SupportTicketDetailCubit, SupportTicketDetailState>(
      listener: _onStateChanged,
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          iconTheme: Theme.of(context).iconTheme,
          title: Text('Chamado'.toUpperCase(), style: textTheme.bodyMedium),
          actions: _adminActions(state),
        ),
        body: switch (state) {
          SupportTicketDetailLoaded(:final detail, :final sending) => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: context.read<SupportTicketDetailCubit>().load,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Header(detail: detail),
                      for (final message in detail.messages)
                        _MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          onOpenAttachment: (url) =>
                              widget.openAttachment(context, url),
                        ),
                      if (detail.resolution case final resolution?)
                        _Resolution(resolution: resolution),
                    ],
                  ),
                ),
              ),
              if (detail.canReply)
                _Composer(sending: sending, pickFile: widget.pickFile)
              else
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Este chamado foi encerrado e não recebe mais mensagens.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
          SupportTicketDetailLoadFailure(:final failure) => _LoadError(
            failure: failure,
          ),
          SupportTicketDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final SupportTicketDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ticket = detail.ticket;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          Text(ticket.subject, style: textTheme.bodyMedium),
          SupportTicketStatusChip(status: ticket.status),
          Text(
            [
              ticket.category.label,
              if (ticket.orderNumber case final number?) 'Pedido $number',
            ].join(' · '),
            style: textTheme.bodySmall,
          ),
          Text(
            'Aberto em ${formatDateTime(ticket.openedAt)}',
            style: textTheme.bodySmall,
          ),
          Text(detail.description, style: textTheme.bodyLarge),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.onOpenAttachment,
  });

  final SupportMessageEntity message;
  final ValueChanged<String> onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final attachmentUrl = message.attachmentUrl;

    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          color: message.mine
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppColors.secondaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: [
              Text(
                message.mine ? 'Você' : message.senderName,
                style: textTheme.bodySmall,
              ),
              Text(message.message, style: textTheme.bodyLarge),
              if (attachmentUrl != null)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => onOpenAttachment(attachmentUrl),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Ver anexo'),
                ),
              Text(
                formatDateTime(message.createdAt),
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 12,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Resolution extends StatelessWidget {
  const _Resolution({required this.resolution});

  final String resolution;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: AppColors.warningBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4.0,
        children: [
          Text('Decisão do suporte', style: textTheme.bodyMedium),
          Text(resolution, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.sending, required this.pickFile});

  final bool sending;
  final Future<UploadFile?> Function(BuildContext context) pickFile;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  UploadFile? _file;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await widget.pickFile(context);
    if (file == null || !mounted) return;
    setState(() => _file = file);
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final sent = await context.read<SupportTicketDetailCubit>().send(
      _messageController.text.trim(),
      file: _file,
    );
    if (!sent || !mounted) return;
    _messageController.clear();
    setState(() => _file = null);
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (file != null)
                InputChip(
                  label: Text(file.filename),
                  onDeleted: widget.sending
                      ? null
                      : () => setState(() => _file = null),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    tooltip: 'Anexar arquivo',
                    onPressed: widget.sending ? null : _pick,
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: ShoeTextFormField(
                      hintText: 'Escreva uma mensagem',
                      controller: _messageController,
                      validator: FieldValidators.combine([
                        FieldValidators.required,
                        FieldValidators.maxLength(2000),
                      ]),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: 4,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar mensagem',
                    onPressed: widget.sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              onPressed: context.read<SupportTicketDetailCubit>().load,
              text: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }
}
