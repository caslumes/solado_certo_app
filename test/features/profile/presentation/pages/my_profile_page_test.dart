import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solado_certo_app/core/error/failure.dart';
import 'package:solado_certo_app/core/files/upload_file.dart';
import 'package:solado_certo_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/entities/podological_profile.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';
import 'package:solado_certo_app/features/profile/domain/enum/footstrike_type.dart';
import 'package:solado_certo_app/features/profile/domain/enum/user_role.dart';
import 'package:solado_certo_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/my_profile_page.dart';

import '../../../../support/builders.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockProfileBloc bloc;
  late MockAuthBloc authBloc;

  final revokeButton = find.text('RETIRAR CONSENTIMENTO');
  final becomeSellerButton = find.text('QUERO VENDER');
  const photo = UploadFile(bytes: [1, 2, 3], filename: 'foto.jpg');
  late UploadFile? pickedPhoto;

  ProfileData buildData({
    bool hasConsent = true,
    bool isSeller = false,
    String avatarUrl = '',
  }) => ProfileData(
    profile: ProfileEntity(
      name: buildProfile().name,
      email: buildProfile().email,
      phone: buildProfile().phone,
      avatarUrl: avatarUrl,
    ),
    addresses: const [],
    podologicalProfile: PodologicalProfileEntity(
      footstrikeType: hasConsent ? FootstrikeType.pronated : null,
    ),
    painPoints: const [],
    hasPodologicalConsent: hasConsent,
    roles: [UserRole.buyer, if (isSeller) UserRole.seller],
  );

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ProfileBloc>.value(value: bloc),
        ],
        child: MyProfilePage(
          addAddress: (_) async {},
          pickPhoto: () async => pickedPhoto,
        ),
      ),
    ),
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    registerFallbackValue(LoadProfileEvent());
    registerFallbackValue(SignOutEvent());
  });

  setUp(() {
    pickedPhoto = photo;
    bloc = MockProfileBloc();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthUnauthenticated());
    when(() => bloc.state).thenReturn(ProfileLoaded(data: buildData()));
  });

  testWidgets('shows the saved data in the three sections', (tester) async {
    await pumpPage(tester);

    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('ENDEREÇOS'), findsOneWidget);
    expect(find.text('PERFIL PODOLÓGICO'), findsOneWidget);
    expect(revokeButton, findsOneWidget);
  });

  testWidgets('hides withdrawal when there is no consent', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(ProfileLoaded(data: buildData(hasConsent: false)));
    await pumpPage(tester);

    expect(revokeButton, findsNothing);
  });

  testWidgets('places withdrawal below the save button', (tester) async {
    await pumpPage(tester);

    final save = tester.getTopLeft(find.text('SALVAR PERFIL PODOLÓGICO'));
    expect(tester.getTopLeft(revokeButton).dy, greaterThan(save.dy));
  });

  testWidgets('asks for confirmation before withdrawing consent', (
    tester,
  ) async {
    await pumpPage(tester);

    await tap(tester, revokeButton);
    expect(find.text('Retirar consentimento?'), findsOneWidget);
    await tap(tester, find.text('Cancelar'));
    verifyNever(() => bloc.add(any()));

    await tap(tester, revokeButton);
    await tap(tester, find.text('Retirar e excluir'));
    verify(
      () => bloc.add(any(that: isA<RevokePodologicalConsentEvent>())),
    ).called(1);
  });

  group('avatar', () {
    testWidgets('uploads the picked photo', (tester) async {
      await pumpPage(tester);

      expect(find.text('Remover foto'), findsNothing);
      await tap(tester, find.text('Adicionar foto'));

      final event =
          verify(() => bloc.add(captureAny())).captured.single
              as ChangeAvatarEvent;
      expect(event.photo, same(photo));
    });

    testWidgets('does nothing when the picker is cancelled', (tester) async {
      pickedPhoto = null;
      await pumpPage(tester);

      await tap(tester, find.text('Adicionar foto'));

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('removes an existing photo', (tester) async {
      when(() => bloc.state).thenReturn(
        ProfileLoaded(
          data: buildData(avatarUrl: '/files/public/avatars/a.jpg'),
        ),
      );
      await pumpPage(tester);

      expect(find.text('Alterar foto'), findsOneWidget);
      await tap(tester, find.text('Remover foto'));

      verify(() => bloc.add(any(that: isA<RemoveAvatarEvent>()))).called(1);
    });
  });

  group('seller', () {
    testWidgets('a buyer can become a seller', (tester) async {
      await pumpPage(tester);

      await tap(tester, becomeSellerButton);

      verify(() => bloc.add(any(that: isA<BecomeSellerEvent>()))).called(1);
    });

    testWidgets('a seller sees the active account instead', (tester) async {
      when(
        () => bloc.state,
      ).thenReturn(ProfileLoaded(data: buildData(isSeller: true)));
      await pumpPage(tester);

      expect(becomeSellerButton, findsNothing);
      expect(find.text('MEUS ANÚNCIOS'), findsOneWidget);
      expect(
        find.textContaining('Sua conta de vendedor está ativa'),
        findsOneWidget,
      );
    });
  });

  testWidgets('saves the personal data', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), ' Maria Lima ');
    await tap(tester, find.text('SALVAR DADOS PESSOAIS'));

    final event =
        verify(() => bloc.add(captureAny())).captured.single
            as SavePersonalDataEvent;
    expect(event.name, 'Maria Lima');
  });

  testWidgets('shows a notice after saving', (tester) async {
    whenListen(
      bloc,
      Stream<ProfileState>.fromIterable([
        ProfileLoaded(
          data: buildData(hasConsent: false),
          notice: ProfileNotice.podologicalConsentRevoked,
        ),
      ]),
      initialState: ProfileLoaded(data: buildData()),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(
      find.text(ProfileNotice.podologicalConsentRevoked.message),
      findsOneWidget,
    );
  });

  testWidgets('signs out', (tester) async {
    await pumpPage(tester);

    await tap(tester, find.text('SAIR'));

    verify(() => authBloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });

  testWidgets('signs out when the session expired', (tester) async {
    whenListen(
      bloc,
      Stream<ProfileState>.fromIterable([
        ProfileLoaded(data: buildData(), failure: UnauthorizedFailure()),
      ]),
      initialState: ProfileLoaded(data: buildData()),
    );
    await pumpPage(tester);
    await tester.pump();

    verify(() => authBloc.add(any(that: isA<SignOutEvent>()))).called(1);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(ProfileLoadFailure(failure: NetworkFailure()));
    await pumpPage(tester);

    await tap(tester, find.text('TENTAR NOVAMENTE'));

    verify(() => bloc.add(any(that: isA<LoadProfileEvent>()))).called(1);
  });
}
