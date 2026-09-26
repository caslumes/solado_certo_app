import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/get_profile_use_case.dart';
import 'package:solado_certo_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:solado_certo_app/features/profile/domain/entities/profile.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final GetProfileUseCase getProfileUseCase;
  final SignOutUseCase signOutUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.getProfileUseCase,
    required this.signOutUseCase,
    required this.signUpUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<SignUpEvent>(_onSignUp);
  }

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final profile = await getProfileUseCase.execute();
      emit(AuthAuthenticated(user: profile));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await signUpUseCase.execute(
        event.name,
        event.email,
        event.phone,
        event.password,
      );
      emit(AuthSignUpSuccess());
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await signInUseCase.execute(event.email, event.password);
      final profile = await getProfileUseCase.execute();
      emit(AuthAuthenticated(user: profile));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await signOutUseCase.execute();
      emit(AuthUnauthenticated());
    } catch (e) {}
    emit(AuthUnauthenticated());
  }
}

class AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class SignUpEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  SignUpEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent({required this.email, required this.password});
}

class SignOutEvent extends AuthEvent {}

class AuthState {}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final ProfileEntity user;

  AuthAuthenticated({required this.user});
}

class AuthSignUpSuccess extends AuthState {}
