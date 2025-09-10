import 'package:supabase_flutter/supabase_flutter.dart';

// Domain - Repositories
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/driver_repository.dart';
import '../domain/repositories/driver_status_repository.dart';

// Domain - Use Cases
import '../domain/usecases/login_use_case.dart';
import '../domain/usecases/register_use_case.dart';
import '../domain/usecases/get_user_profile_use_case.dart';

// Presentation - BLoCs
import '../presentation/blocs/login_bloc.dart';
import '../presentation/blocs/register_bloc.dart';

// Data - Data Sources
import '../data/datasources/auth_api_data_source.dart';
import '../data/datasources/user_api_data_source.dart';
import '../data/datasources/user_local_data_source.dart';
import '../data/datasources/driver_status_api_data_source.dart';

// Data - Repository Implementations
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/driver_repository_impl.dart';
import '../data/repositories/driver_status_repository_impl.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Data Sources
  late AuthApiDataSource authApiDataSource;
  late UserApiDataSource userApiDataSource;
  late UserLocalDataSource userLocalDataSource;
  late DriverStatusApiDataSource driverStatusApiDataSource;

  // Repositories
  late AuthRepository authRepository;
  late UserRepository userRepository;
  late DriverRepository driverRepository;
  late DriverStatusRepository driverStatusRepository;

  // Use cases
  late LoginUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late GetUserProfileUseCase getUserProfileUseCase;

  // BLoCs (optional - can be created where needed)
  LoginBloc createLoginBloc() => LoginBloc(loginUseCase);
  RegisterBloc createRegisterBloc() => RegisterBloc(registerUseCase);

  void init(SupabaseClient supabase) {
    // Initialize data sources
    authApiDataSource = AuthApiDataSource(supabase);
    userApiDataSource = UserApiDataSource(supabase);
    userLocalDataSource = UserLocalDataSource();
    driverStatusApiDataSource = DriverStatusApiDataSource(supabase);

    // Initialize repositories (injecting data sources)
    authRepository = AuthRepositoryImpl(authApiDataSource);
    userRepository = UserRepositoryImpl(supabase); // TODO: Update to use data sources
    driverRepository = DriverRepositoryImpl(supabase); // TODO: Update to use data sources
    driverStatusRepository = DriverStatusRepositoryImpl(driverStatusApiDataSource);

    // Initialize use cases (injecting repositories)
    loginUseCase = LoginUseCase(authRepository);
    registerUseCase = RegisterUseCase(authRepository);
    getUserProfileUseCase = GetUserProfileUseCase(userRepository);
  }
}