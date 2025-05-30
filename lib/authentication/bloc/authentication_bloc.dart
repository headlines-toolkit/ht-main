import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_shared/ht_shared.dart'
    show
        AuthenticationException,
        HtHttpException,
        InvalidInputException,
        NetworkException,
        OperationFailedException,
        ServerException,
        User;

part 'authentication_event.dart';
part 'authentication_state.dart';

/// {@template authentication_bloc}
/// Bloc responsible for managing the authentication state of the application.
/// {@endtemplate}
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// {@macro authentication_bloc}
  AuthenticationBloc({required HtAuthRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(AuthenticationInitial()) {
    // Listen to authentication state changes from the repository
    _authenticationRepository.authStateChanges.listen(
      (user) => add(_AuthenticationUserChanged(user: user)),
    );

    on<_AuthenticationUserChanged>(_onAuthenticationUserChanged);
    on<AuthenticationRequestSignInCodeRequested>(
      _onAuthenticationRequestSignInCodeRequested,
    );
    on<AuthenticationVerifyCodeRequested>(_onAuthenticationVerifyCodeRequested);
    on<AuthenticationAnonymousSignInRequested>(
      _onAuthenticationAnonymousSignInRequested,
    );
    on<AuthenticationSignOutRequested>(_onAuthenticationSignOutRequested);
  }

  final HtAuthRepository _authenticationRepository;

  /// Handles [_AuthenticationUserChanged] events.
  Future<void> _onAuthenticationUserChanged(
    _AuthenticationUserChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (event.user != null) {
      emit(AuthenticationAuthenticated(user: event.user!));
    } else {
      emit(AuthenticationUnauthenticated());
    }
  }

  /// Handles [AuthenticationRequestSignInCodeRequested] events.
  Future<void> _onAuthenticationRequestSignInCodeRequested(
    AuthenticationRequestSignInCodeRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    // Validate email format (basic check)
    if (event.email.isEmpty || !event.email.contains('@')) {
      emit(const AuthenticationFailure('Please enter a valid email address.'));
      return;
    }
    emit(
      AuthenticationRequestCodeLoading(),
    ); // Indicate code request is sending
    try {
      await _authenticationRepository.requestSignInCode(event.email);
      emit(
        AuthenticationCodeSentSuccess(email: event.email),
      ); // Confirm code requested and include email
    } on InvalidInputException catch (e) {
      emit(AuthenticationFailure('Invalid input: ${e.message}'));
    } on NetworkException catch (_) {
      emit(const AuthenticationFailure('Network error occurred.'));
    } on ServerException catch (e) {
      emit(AuthenticationFailure('Server error: ${e.message}'));
    } on OperationFailedException catch (e) {
      emit(AuthenticationFailure('Operation failed: ${e.message}'));
    } on HtHttpException catch (e) {
      // Catch any other HtHttpException subtypes
      emit(AuthenticationFailure('HTTP error: ${e.message}'));
    } catch (e) {
      // Catch any other unexpected errors
      emit(AuthenticationFailure('An unexpected error occurred: $e'));
      // Optionally log the stackTrace here
    }
  }

  /// Handles [AuthenticationVerifyCodeRequested] events.
  Future<void> _onAuthenticationVerifyCodeRequested(
    AuthenticationVerifyCodeRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading()); // Indicate code verification is loading
    try {
      await _authenticationRepository.verifySignInCode(event.email, event.code);
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting AuthenticationAuthenticated.
    } on InvalidInputException catch (e) {
      emit(AuthenticationFailure('Invalid input: ${e.message}'));
    } on AuthenticationException catch (e) {
      emit(AuthenticationFailure('Authentication failed: ${e.message}'));
    } on NetworkException catch (_) {
      emit(const AuthenticationFailure('Network error occurred.'));
    } on ServerException catch (e) {
      emit(AuthenticationFailure('Server error: ${e.message}'));
    } on OperationFailedException catch (e) {
      emit(AuthenticationFailure('Operation failed: ${e.message}'));
    } on HtHttpException catch (e) {
      // Catch any other HtHttpException subtypes
      emit(AuthenticationFailure('HTTP error: ${e.message}'));
    } catch (e) {
      // Catch any other unexpected errors
      emit(AuthenticationFailure('An unexpected error occurred: $e'));
      // Optionally log the stackTrace here
    }
  }

  /// Handles [AuthenticationAnonymousSignInRequested] events.
  Future<void> _onAuthenticationAnonymousSignInRequested(
    AuthenticationAnonymousSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading()); // Indicate anonymous sign-in is loading
    try {
      await _authenticationRepository.signInAnonymously();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting AuthenticationAuthenticated.
    } on NetworkException catch (_) {
      emit(const AuthenticationFailure('Network error occurred.'));
    } on ServerException catch (e) {
      emit(AuthenticationFailure('Server error: ${e.message}'));
    } on OperationFailedException catch (e) {
      emit(AuthenticationFailure('Operation failed: ${e.message}'));
    } on HtHttpException catch (e) {
      // Catch any other HtHttpException subtypes
      emit(AuthenticationFailure('HTTP error: ${e.message}'));
    } catch (e) {
      emit(AuthenticationFailure('An unexpected error occurred: $e'));
    }
  }

  /// Handles [AuthenticationSignOutRequested] events.
  Future<void> _onAuthenticationSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationLoading()); // Indicate sign-out is loading
    try {
      await _authenticationRepository.signOut();
      // On success, the _AuthenticationUserChanged listener will handle
      // emitting AuthenticationUnauthenticated.
    } on NetworkException catch (_) {
      emit(const AuthenticationFailure('Network error occurred.'));
    } on ServerException catch (e) {
      emit(AuthenticationFailure('Server error: ${e.message}'));
    } on OperationFailedException catch (e) {
      emit(AuthenticationFailure('Operation failed: ${e.message}'));
    } on HtHttpException catch (e) {
      // Catch any other HtHttpException subtypes
      emit(AuthenticationFailure('HTTP error: ${e.message}'));
    } catch (e) {
      emit(AuthenticationFailure('An unexpected error occurred: $e'));
    }
  }
}
