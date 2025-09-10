part of 'register_bloc.dart';

abstract class RegisterEvent {}

class RegisterButtonPressed extends RegisterEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final String userType;

  RegisterButtonPressed({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    this.userType = 'passenger',
  });
}