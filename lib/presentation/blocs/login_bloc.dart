import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_use_case.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase _loginUseCase;

  LoginBloc(this._loginUseCase) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final result = await _loginUseCase(
        email: event.email,
        password: event.password,
      );
      if (result['success'] == true) {
        emit(LoginSuccess());
      } else {
        emit(LoginFailure(message: result['message'] ?? 'Erro desconhecido'));
      }
    } catch (e) {
      emit(LoginFailure(message: e.toString()));
    }
  }
}