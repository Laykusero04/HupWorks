import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// PARKED — not wired into the app UI.
///
/// Login / signup / logout currently call [AuthService] directly.
/// Re-enable via `BlocProvider` in `app.dart` when screens migrate off
/// imperative auth calls.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (!_authRepository.isLoggedIn) {
        emit(Unauthenticated());
        return;
      }
      final profile = await _authRepository.getCurrentProfile();
      if (profile == null) {
        emit(Unauthenticated());
        return;
      }
      emit(Authenticated(profile: profile, role: profile.role));
    } on Failure {
      emit(Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(email: event.email, password: event.password);
      final profile = await _authRepository.getCurrentProfile();
      if (profile == null) {
        emit(const AuthError('Profile not found'));
        return;
      }
      emit(Authenticated(profile: profile, role: profile.role));
    } on Failure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
        phone: event.phone,
      );
      final profile = await _authRepository.getCurrentProfile();
      if (profile == null) {
        emit(const AuthError('Profile creation failed'));
        return;
      }
      emit(Authenticated(profile: profile, role: profile.role));
    } on Failure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.signOut();
    } catch (_) {
      // Even if sign-out fails server-side, treat the user as logged out locally
    }
    emit(Unauthenticated());
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(email: event.email);
      emit(AuthPasswordResetSent());
    } on Failure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
