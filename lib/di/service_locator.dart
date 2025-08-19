import 'package:get_it/get_it.dart';
import '../api/api_client.dart';
import '../api/services/auth_api.dart';
import '../utils/navigation_service.dart';
import '../utils/secure_storage.dart';
import '../repositories/user_repository.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Utils
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // API
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<AuthApi>(() => AuthApi(getIt<ApiClient>()));

  // Repositories
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(getIt<SecureStorage>()),
  );
}
