import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/presentation/bloc/paged_list_cubit.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/features/admin/domain/entities/admin_entities.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';

PageResult<T> pageResult<T>(AdminPageEntity<T> page) =>
    (items: page.items, page: page.currentPage, hasNext: page.hasNext);

void showAdminNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      body: body,
    );
  }
}

class AdminListView<T, F> extends StatefulWidget {
  const AdminListView({
    super.key,
    this.header,
    required this.emptyText,
    required this.itemBuilder,
  });

  final Widget? header;
  final String emptyText;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<AdminListView<T, F>> createState() => _AdminListViewState<T, F>();
}

class _AdminListViewState<T, F> extends State<AdminListView<T, F>> {
  static const _loadMoreExtent = 400.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < _loadMoreExtent) {
      context.read<PagedListCubit<T, F>>().loadMore();
    }
  }

  void _checkFill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _onScroll();
    });
  }

  void _onStateChanged(BuildContext context, PagedListState<T, F> state) {
    final failure = state.failure;
    if (failure == null) return _checkFill();
    if (failure is UnauthorizedFailure) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthBloc>().add(SignOutEvent());
      return;
    }
    if (state.status != PagedListStatus.loaded) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PagedListCubit<T, F>>();
    final header = widget.header;

    return Column(
      children: [
        ?header,
        Expanded(
          child: BlocConsumer<PagedListCubit<T, F>, PagedListState<T, F>>(
            listenWhen: (previous, current) =>
                current.failure != null ||
                (current.status == PagedListStatus.loaded &&
                    current.items.length != previous.items.length),
            listener: _onStateChanged,
            builder: (context, state) => switch (state.status) {
              PagedListStatus.loaded => RefreshIndicator(
                onRefresh: cubit.load,
                child: state.items.isEmpty
                    ? _Empty(text: widget.emptyText)
                    : ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            state.items.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final item = state.items[index];
                          return Builder(
                            builder: (context) =>
                                widget.itemBuilder(context, item),
                          );
                        },
                      ),
              ),
              PagedListStatus.failure => AdminLoadError(
                failure: state.failure!,
                onRetry: cubit.load,
              ),
              PagedListStatus.loading || PagedListStatus.initial =>
                const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        const Icon(
          Icons.inbox_outlined,
          size: 48,
          color: AppColors.tertiaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class AdminLoadError extends StatelessWidget {
  const AdminLoadError({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Failure failure;
  final VoidCallback onRetry;

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
            ShoeTextButton(onPressed: onRetry, text: 'Tentar novamente'),
          ],
        ),
      ),
    );
  }
}

class AdminFilterChips<V> extends StatelessWidget {
  const AdminFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(V, String)> options;
  final V selected;
  final ValueChanged<V> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8.0,
        children: [
          for (final (value, label) in options)
            ChoiceChip(
              label: Text(label),
              selected: value == selected,
              onSelected: (_) {
                if (value != selected) onSelected(value);
              },
            ),
        ],
      ),
    );
  }
}

class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.hintText,
    required this.initialValue,
    required this.onSubmitted,
  });

  final String hintText;
  final String initialValue;
  final ValueChanged<String> onSubmitted;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onSubmitted('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _controller,
        maxLength: 100,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => widget.onSubmitted(value.trim()),
        decoration: InputDecoration(
          hintText: widget.hintText,
          counterText: '',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Limpar busca',
            onPressed: _clear,
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    );
  }
}

class AdminTag extends StatelessWidget {
  const AdminTag({super.key, required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = highlight
        ? (AppColors.warningBackgroundColor, AppColors.warningColor)
        : (AppColors.secondaryColor, AppColors.tertiaryColor);

    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class AdminTile extends StatelessWidget {
  const AdminTile({
    super.key,
    required this.title,
    this.tags = const [],
    this.lines = const [],
    this.footnote,
    this.trailing,
    this.onTap,
  });

  final String title;
  final List<Widget> tags;
  final List<String> lines;
  final String? footnote;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final footnote = this.footnote;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.0,
                children: [
                  Text(title, style: textTheme.bodyMedium),
                  if (tags.isNotEmpty)
                    Wrap(spacing: 8.0, runSpacing: 4.0, children: tags),
                  for (final line in lines)
                    Text(line, style: textTheme.bodySmall),
                  if (footnote != null)
                    Text(
                      footnote,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 12,
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
