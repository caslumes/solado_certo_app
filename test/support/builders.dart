import 'package:dio/dio.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_filter_options.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_item.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/category.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/condition.dart';
import 'package:solado_certo_app/features/catalog/domain/entities/purpose.dart';
import 'package:solado_certo_app/features/onboarding/domain/entities/onboarding.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_status.dart';
import 'package:solado_certo_app/features/onboarding/domain/enum/onboarding_step.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

ProfileEntity buildProfile() => ProfileEntity(
  name: 'Maria Souza',
  email: 'maria@example.com',
  phone: '19999999999',
  avatarUrl: '',
);

OnboardingEntity buildOnboarding({
  OnboardingStep step = OnboardingStep.welcome,
  OnboardingStatus status = OnboardingStatus.inProgress,
}) => OnboardingEntity(currentStep: step, status: status);

OnboardingDraft buildDraft({OnboardingStep step = OnboardingStep.welcome}) =>
    OnboardingDraft(
      onboarding: buildOnboarding(step: step),
      profile: buildProfile(),
      addresses: const [],
      podologicalProfile: PodologicalProfileEntity(),
    );

DioException buildDioException({
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: requestOptions, statusCode: statusCode),
  );
}

CatalogItemEntity buildCatalogItem({String id = '601', int stock = 10}) =>
    CatalogItemEntity(id: id, title: 'Palmilha $id', price: 89.9, stock: stock);

CatalogPageEntity buildCatalogPage({
  List<CatalogItemEntity>? items,
  int page = 1,
  int totalItems = 1,
  bool hasNext = false,
}) => CatalogPageEntity(
  items: items ?? [buildCatalogItem()],
  currentPage: page,
  totalItems: totalItems,
  hasNext: hasNext,
);

const catalogFilterOptions = CatalogFilterOptions(
  categories: [
    CategoryEntity(
      id: '301',
      name: 'Palmilhas',
      children: [CategoryEntity(id: '305', name: 'Palmilhas sob medida')],
    ),
    CategoryEntity(id: '302', name: 'Calçados ortopédicos'),
  ],
  purposes: [PurposeEntity(code: 'prevention', name: 'Prevenção')],
  conditions: [ConditionEntity(id: '501', name: 'Fascite plantar')],
);
