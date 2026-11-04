import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/usecases/support_use_cases.dart';
import 'package:solado_certo_app/features/support/presentation/bloc/support_ticket_form_cubit.dart';
import 'package:solado_certo_app/features/support/presentation/pages/support_ticket_detail_page.dart';

class SupportTicketFormPage extends StatefulWidget {
  const SupportTicketFormPage({
    super.key,
    this.orderId,
    this.orderNumber,
    this.category,
    this.onCreated = _openTicket,
  });

  final String? orderId;
  final String? orderNumber;
  final SupportTicketCategory? category;
  final void Function(BuildContext context, SupportTicketDetailEntity detail)
  onCreated;

  static void _openTicket(
    BuildContext context,
    SupportTicketDetailEntity detail,
  ) {
    Navigator.of(
      context,
    ).pushReplacement(SupportTicketDetailPage.route(detail.ticket.id));
  }

  static Route<void> route({
    String? orderId,
    String? orderNumber,
    SupportTicketCategory? category,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SupportTicketFormCubit(
          createTicketUseCase: getIt<CreateSupportTicketUseCase>(),
        ),
        child: SupportTicketFormPage(
          orderId: orderId,
          orderNumber: orderNumber,
          category: category,
        ),
      ),
    );
  }

  @override
  State<SupportTicketFormPage> createState() => _SupportTicketFormPageState();
}

class _SupportTicketFormPageState extends State<SupportTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final List<SupportTicketCategory> _categories = widget.orderId == null
      ? SupportTicketCategory.withoutOrder
      : SupportTicketCategory.values;
  late SupportTicketCategory _category = widget.category ?? _categories.first;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SupportTicketFormCubit>().submit(
      NewSupportTicket(
        category: _category,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        orderId: widget.orderId,
      ),
    );
  }

  void _onStateChanged(BuildContext context, SupportTicketFormState state) {
    final created = state.created;
    if (created != null) return widget.onCreated(context, created);
    final failure = state.failure;
    if (failure == null) return;
    if (failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final orderNumber = widget.orderNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: Theme.of(context).iconTheme,
        title: Text('Abrir chamado'.toUpperCase(), style: textTheme.bodyMedium),
      ),
      body: BlocConsumer<SupportTicketFormCubit, SupportTicketFormState>(
        listener: _onStateChanged,
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16.0,
              children: [
                if (orderNumber != null)
                  Text('Pedido $orderNumber', style: textTheme.bodyMedium)
                else
                  Text(
                    'Problema com um pedido ou pagamento? Abra o chamado pela '
                    'tela do pedido.',
                    style: textTheme.bodySmall,
                  ),
                DropdownButtonFormField<SupportTicketCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Assunto'),
                  items: [
                    for (final category in _categories)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (category) {
                    if (category != null) _category = category;
                  },
                ),
                ShoeTextFormField(
                  key: const ValueKey('ticket-subject'),
                  labelText: 'Título'.toUpperCase(),
                  hintText: 'Resuma o problema',
                  controller: _subjectController,
                  validator: FieldValidators.textLength(5, 150),
                  textCapitalization: TextCapitalization.sentences,
                ),
                ShoeTextFormField(
                  key: const ValueKey('ticket-description'),
                  labelText: 'Descrição'.toUpperCase(),
                  hintText: 'Conte o que aconteceu com o máximo de detalhes',
                  controller: _descriptionController,
                  validator: FieldValidators.textLength(20, 2000),
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 6,
                ),
                Text(
                  'Depois de abrir o chamado, você pode anexar fotos ou '
                  'documentos pelas mensagens.',
                  style: textTheme.bodySmall,
                ),
                ShoeTextButton(
                  isLoading: state.sending,
                  onPressed: _submit,
                  text: 'Abrir chamado',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
