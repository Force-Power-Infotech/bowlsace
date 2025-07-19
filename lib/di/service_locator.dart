import 'package:get_it/get_it.dart';
import '../api/api_client.dart';
import '../api/api_error_handler.dart';
import '../api/services/auth_api.dart';
import '../api/services/practice_api.dart';
import '../api/services/drill_group_api.dart';
import '../api/services/search_api.dart';
import '../repositories/auth_repository.dart';
import '../repositories/practice_repository.dart';
import '../repositories/search_repository.dart';
import '../utils/connectivity_service.dart';
import '../utils/local_storage.dart';
import '../utils/navigation_service.dart';
import '../utils/notification_service.dart';
import '../utils/secure_storage.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Utils
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  getIt.registerLazySingleton<LocalStorage>(() => LocalStorage());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // API
  getIt.registerLazySingleton<TokenManager>(() => TokenManager());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<AuthApi>(() => AuthApi(getIt<ApiClient>()));
  getIt.registerLazySingleton<PracticeApi>(
    () => PracticeApi(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<DrillGroupApi>(
    () => DrillGroupApi(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SearchApi>(
    () => SearchApi(getIt<ApiClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<AuthApi>(), getIt<SecureStorage>()),
  );
  getIt.registerLazySingleton<PracticeRepository>(
    () => PracticeRepository(
      getIt<PracticeApi>(),
      getIt<DrillGroupApi>(),
      getIt<LocalStorage>(),
    ),
  );
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepository(
      getIt<SearchApi>(),
      getIt<LocalStorage>(),
    ),
  );

  // Services
  getIt.registerLazySingleton<ApiErrorHandler>(
    () => ApiErrorHandler(
      getIt<NavigationService>(),
      getIt<NotificationService>(),
    ),
  );
}
