import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_form_field.dart';
import 'package:solado_certo_app/core/validation/field_validators.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/product_image.dart';
import 'package:solado_certo_app/features/orders/domain/entities/order.dart';
import 'package:solado_certo_app/features/reviews/domain/entities/review.dart';
import 'package:solado_certo_app/features/reviews/domain/usecases/review_use_cases.dart';
import 'package:solado_certo_app/features/reviews/presentation/bloc/review_form_cubit.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/comfort_labels.dart';
import 'package:solado_certo_app/features/reviews/presentation/components/rating_stars.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.item,
    required this.sellerName,
    this.openSupport = supportUnavailable,
  });

  final OrderItemEntity item;
  final String sellerName;

  final void Function(BuildContext context) openSupport;

  static Route<bool> route({
    required String orderId,
    required OrderItemEntity item,
    required String sellerName,
  }) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => ReviewFormCubit(
          createReviewUseCase: getIt<CreateReviewUseCase>(),
          orderId: orderId,
          itemId: item.id!,
        ),
        child: ReviewPage(item: item, sellerName: sellerName),
      ),
    );
  }

  static void supportUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('A abertura de chamados ainda não está disponível.'),
        ),
      );
  }

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const _maxText = 2000;

  final _formKey = GlobalKey<FormState>();
  final _feedback = TextEditingController();
  final _comment = TextEditingController();
  int? _productRating;
  int? _sellerRating;
  int? _comfortRating;
  bool _hadProblems = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _feedback.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _showErrors = true);
    final formValid = _formKey.currentState!.validate();
    final productRating = _productRating;
    final sellerRating = _sellerRating;
    if (!formValid || productRating == null || sellerRating == null) return;

    context.read<ReviewFormCubit>().submit(
      NewReview(
        productRating: productRating,
        sellerRating: sellerRating,
        comfortRating: _comfortRating,
        comment: _comment.text,
        adaptationFeedback: _feedback.text,
      ),
      hadProblems: _hadProblems,
    );
  }

  Future<void> _onSent(bool suggestSupport) async {
    final navigator = Navigator.of(context);
    final openSupport = suggestSupport && await _askSupport() == true;
    if (!mounted) return;
    if (openSupport) widget.openSupport(context);
    navigator.pop(true);
  }

  Future<bool?> _askSupport() {
    final textTheme = Theme.of(context).textTheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Precisa de ajuda?', style: textTheme.bodyMedium),
        content: Text(
          'Sentimos muito que o produto não tenha ido bem. Abra um chamado de '
          'suporte para resolvermos com o vendedor.',
          style: textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abrir suporte'),
          ),
        ],
      ),
    );
  }

  void _onFailure(Failure failure) {
    if (failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
    if (failure is AlreadyReviewedFailure) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const missingRating = 'Escolha de 1 a 5 estrelas.';

    return BlocConsumer<ReviewFormCubit, ReviewFormState>(
      listener: (context, state) {
        if (state.failure case final failure?) return _onFailure(failure);
        if (state.sent != null) _onSent(state.suggestSupport);
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          iconTheme: Theme.of(context).iconTheme,
          title: Text('Avaliar'.toUpperCase(), style: textTheme.bodyMedium),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                spacing: 12.0,
                children: [
                  SizedBox.square(
                    dimension: 56,
                    child: ProductImage(url: widget.item.coverImageUrl),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.title, style: textTheme.bodyLarge),
                        Text(
                          'Vendido por ${widget.sellerName}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StarRatingField(
                label: 'Produto',
                value: _productRating,
                onChanged: (rating) => setState(() => _productRating = rating),
                errorText: _showErrors && _productRating == null
                    ? missingRating
                    : null,
              ),
              const SizedBox(height: 16),
              StarRatingField(
                label: 'Vendedor',
                value: _sellerRating,
                onChanged: (rating) => setState(() => _sellerRating = rating),
                errorText: _showErrors && _sellerRating == null
                    ? missingRating
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Conforto (opcional)', style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final MapEntry(key: rating, value: label)
                      in comfortLabels.entries)
                    ChoiceChip(
                      label: Text(label),
                      selected: _comfortRating == rating,
                      onSelected: (selected) => setState(
                        () => _comfortRating = selected ? rating : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ShoeTextFormField(
                labelText: 'Como foi a adaptação? (opcional)',
                hintText: 'Ex.: tempo até se acostumar, pontos de pressão',
                controller: _feedback,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: FieldValidators.maxLength(_maxText),
              ),
              const SizedBox(height: 4),
              Text(
                'Só você e o vendedor veem a adaptação.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ShoeTextFormField(
                labelText: 'Comentário (opcional)',
                controller: _comment,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: FieldValidators.maxLength(_maxText),
              ),
              const SizedBox(height: 4),
              Text(
                'O comentário aparece na página do produto com seu primeiro '
                'nome.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Tive problemas com o produto',
                  style: textTheme.bodyLarge,
                ),
                value: _hadProblems,
                onChanged: (value) =>
                    setState(() => _hadProblems = value ?? false),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ShoeTextButton(
              onPressed: state.sending || state.sent != null ? null : _submit,
              text: 'Enviar avaliação',
            ),
          ),
        ),
      ),
    );
  }
}
