part of 'register_bloc.dart';

abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final bool needsConfirmation;
  final String message;

  RegisterSuccess({
    required this.needsConfirmation,
    required this.message,
  });
}

class RegisterFailure extends RegisterState {
  final String message;

  RegisterFailure({required this.message});
}