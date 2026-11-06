import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filters.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/all_products.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/category_shortcuts.dart';
import 'package:solado_certo_app/features/catalog/presentation/bloc/home_sections_cubit.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/home_sections.dart';
import 'package:solado_certo_app/features/catalog/presentation/components/search_bar.dart';
import 'package:solado_certo_app/features/catalog/presentation/pages/catalog_page.dart';
import 'package:solado_certo_app/features/notifications/presentation/components/notification_bell.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/become_seller_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/change_avatar_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_roles_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/remove_avatar_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_addresses_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_pain_points_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/has_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/revoke_podological_consent_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/save_podological_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/update_profile_use_case.dart';
import 'package:solado_certo_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/my_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.isSignedIn});

  final bool isSignedIn;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _loadMoreExtent = 600.0;

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
      context.read<CatalogBloc>().add(CatalogNextPageRequested());
    }
  }

  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) _onScroll();
    });
  }

  Future<void> _openProfile(BuildContext context) async {
    final homeSections = context.read<HomeSectionsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(
            getProfileUseCase: getIt<GetProfileUseCase>(),
            updateProfileUseCase: getIt<UpdateProfileUseCase>(),
            getAddressesUseCase: getIt<GetAddressesUseCase>(),
            getPodologicalProfileUseCase: getIt<GetPodologicalProfileUseCase>(),
            savePodologicalProfileUseCase:
                getIt<SavePodologicalProfileUseCase>(),
            getPainPointsUseCase: getIt<GetPainPointsUseCase>(),
            hasPodologicalConsentUseCase: getIt<HasPodologicalConsentUseCase>(),
            revokePodologicalConsentUseCase:
                getIt<RevokePodologicalConsentUseCase>(),
            becomeSellerUseCase: getIt<BecomeSellerUseCase>(),
            changeAvatarUseCase: getIt<ChangeAvatarUseCase>(),
            getRolesUseCase: getIt<GetRolesUseCase>(),
            removeAvatarUseCase: getIt<RemoveAvatarUseCase>(),
          )..add(LoadProfileEvent()),
          child: const MyProfilePage(),
        ),
      ),
    );
    if (!homeSections.isClosed) homeSections.load();
  }

  @override
  Widget build(BuildContext context) {
    const userImage = Image(
      image: AssetImage('assets/images/user.png'),
      width: 70,
    );

    return Scaffold(
      body: BlocListener<CatalogBloc, CatalogState>(
        listenWhen: (previous, current) => current.page != previous.page,
        listener: (context, state) => _fillViewport(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                spacing: 16.0,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Image(
                          image: const AssetImage('assets/images/logo.png'),
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        const Spacer(),
                        if (widget.isSignedIn) const NotificationBell(),
                        widget.isSignedIn
                            ? IconButton(
                                tooltip: 'Meu perfil',
                                onPressed: () => _openProfile(context),
                                icon: userImage,
                              )
                            : InkWell(
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(AuthRoutes.signIn),
                                child: Column(
                                  spacing: 8.0,
                                  children: [
                                    userImage,
                                    Text(
                                      'Entre na sua conta',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(color: AppColors.primaryColor, height: 5),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CategoryShortcuts(),
                      ),
                      Container(color: AppColors.primaryColor, height: 5),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ShoeSearchBar(
                      onSubmitted: (query) => Navigator.of(context).push(
                        CatalogPage.route(
                          context,
                          filters: CatalogFilters(query: query),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: HomeSections(),
                  ),
                ],
              ),
            ),
            const AllProducts(),
          ],
        ),
      ),
    );
  }
}
