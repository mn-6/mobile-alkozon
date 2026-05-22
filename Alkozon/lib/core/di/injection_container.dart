import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_display_name_use_case.dart';
import '../../features/auth/domain/usecases/get_current_user_profile_use_case.dart';
import '../../features/auth/domain/usecases/is_authenticated_use_case.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/catalog/domain/product_image_resolver.dart';
import '../../features/device_security/data/datasources/app_check_remote_data_source.dart';
import '../../features/device_security/data/repositories/device_security_repository_impl.dart';
import '../../features/device_security/domain/repositories/device_security_repository.dart';
import '../../features/device_security/domain/usecases/check_device_security_use_case.dart';
import '../../features/inventory/data/datasources/inventory_remote_data_source.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/notifications/presentation/services/notification_service.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders_realtime/data/services/order_realtime_service.dart';
import '../../features/startup/data/datasources/startup_warmup_remote_data_source.dart';
import '../../features/startup/data/repositories/startup_repository_impl.dart';
import '../../features/startup/domain/repositories/startup_repository.dart';
import '../../features/startup/domain/usecases/wait_for_server_ready_use_case.dart';
import '../../features/work_time/data/datasources/work_log_remote_data_source.dart';
import '../../features/work_time/data/repositories/work_log_repository_impl.dart';
import '../../features/work_time/domain/repositories/work_log_repository.dart';
import '../network/auth_token_refresh_interceptor.dart';
import '../network/connectivity_error_interceptor.dart';
import '../network/dio_factory.dart';
import '../security/login_attempt_limiter.dart';

class InjectionContainer {
  InjectionContainer._();

  static final InjectionContainer instance = InjectionContainer._();

  static InjectionContainer get I => instance;

  late final Dio dio;
  late final AuthRepository authRepository;
  late final OrderRepository orderRepository;
  late final InventoryRepository inventoryRepository;
  late final WorkLogRepository workLogRepository;
  late final DeviceSecurityRepository deviceSecurityRepository;
  late final StartupRepository startupRepository;
  late final AppCheckRemoteDataSource appCheckRemoteDataSource;
  late final LoginAttemptLimiter loginAttemptLimiter;

  late final LoginUseCase loginUseCase;
  late final LogoutUseCase logoutUseCase;
  late final GetCurrentUserProfileUseCase getCurrentUserProfileUseCase;
  late final GetCurrentUserDisplayNameUseCase getCurrentUserDisplayNameUseCase;
  late final IsAuthenticatedUseCase isAuthenticatedUseCase;
  late final CheckDeviceSecurityUseCase checkDeviceSecurityUseCase;
  late final WaitForServerReadyUseCase waitForServerReadyUseCase;

  NotificationService get notificationService => NotificationService.instance;

  OrderRealtimeService get orderRealtimeService => OrderRealtimeService.instance;

  Future<void> init() async {
    loginAttemptLimiter = LoginAttemptLimiter();
    appCheckRemoteDataSource = AppCheckRemoteDataSource();

    final authLocalDataSource = AuthLocalDataSource();
    final authDio = DioFactory.create();
    final authRemoteDataSource = AuthRemoteDataSource(authDio);

    dio = DioFactory.create();
    authRepository = AuthRepositoryImpl(
      dio: dio,
      localDataSource: authLocalDataSource,
      remoteDataSource: authRemoteDataSource,
      onLogout: orderRealtimeService.disconnect,
    );
    dio.interceptors.add(AuthTokenRefreshInterceptor(authRepository));
    dio.interceptors.add(ConnectivityErrorInterceptor());

    final accessToken = await authLocalDataSource.readToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }

    orderRepository = OrderRepositoryImpl(
      OrderRemoteDataSource(authRepository, dio: dio),
    );
    inventoryRepository = InventoryRepositoryImpl(
      InventoryRemoteDataSource(authRepository, dio: dio),
    );
    workLogRepository = WorkLogRepositoryImpl(
      WorkLogRemoteDataSource(authRepository, dio: dio),
    );

    deviceSecurityRepository = DeviceSecurityRepositoryImpl(
      appCheckDataSource: appCheckRemoteDataSource,
    );
    startupRepository = StartupRepositoryImpl(
      StartupWarmupRemoteDataSource(),
    );

    loginUseCase = LoginUseCase(authRepository);
    logoutUseCase = LogoutUseCase(authRepository);
    getCurrentUserProfileUseCase = GetCurrentUserProfileUseCase(authRepository);
    getCurrentUserDisplayNameUseCase = GetCurrentUserDisplayNameUseCase(
      authRepository,
    );
    isAuthenticatedUseCase = IsAuthenticatedUseCase(authRepository);
    checkDeviceSecurityUseCase = CheckDeviceSecurityUseCase(
      deviceSecurityRepository,
    );
    waitForServerReadyUseCase = WaitForServerReadyUseCase(startupRepository);

    await ProductImageResolver.ensureInitialized();
  }
}
