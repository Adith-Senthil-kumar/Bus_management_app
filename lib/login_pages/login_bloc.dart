import 'package:flutter_bloc/flutter_bloc.dart';

/// Events
abstract class LoginEvent {}

class ToggleSignUpMode extends LoginEvent {}

class TogglePasswordVisibility extends LoginEvent {}

/// States
class LoginState {
  final bool isSignUpMode;
  final bool isPasswordVisible;

  LoginState({
    required this.isSignUpMode,
    required this.isPasswordVisible,
  });

  LoginState copyWith({
    bool? isSignUpMode,
    bool? isPasswordVisible,
  }) {
    return LoginState(
      isSignUpMode: isSignUpMode ?? this.isSignUpMode,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }
}

/// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc()
      : super(LoginState(
          isSignUpMode: false,
          isPasswordVisible: false,
        )) {
    on<ToggleSignUpMode>((event, emit) {
      emit(state.copyWith(isSignUpMode: !state.isSignUpMode));
    });

    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
    });
  }
}