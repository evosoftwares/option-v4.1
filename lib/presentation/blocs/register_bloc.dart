import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/register_use_case.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUseCase _registerUseCase;

  RegisterBloc(this._registerUseCase) : super(RegisterInitial()) {
    on<RegisterButtonPressed>(_onRegisterButtonPressed);
  }

  Future<void> _onRegisterButtonPressed(
    RegisterButtonPressed event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    try {
      final result = await _registerUseCase(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phone: event.phone,
        userType: event.userType,
      );
      
      if (result['success'] == true) {
        emit(RegisterSuccess(
          needsConfirmation: result['needs_confirmation'] ?? false,
          message: result['message'] ?? 'Conta criada com sucesso!',
        ));
      } else {
        emit(RegisterFailure(message: result['message'] ?? 'Erro desconhecido'));
      }
    } catch (e) {
      emit(RegisterFailure(message: e.toString()));
    }
  }
}