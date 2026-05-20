import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/order.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource(this._authRepository, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            ),
          );

  final AuthRepository _authRepository;
  final Dio _dio;

  Future<StaffCombinedOrders> getStaffCombinedOrders() async {
    final token = await _authRepository.getAccessToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    int page = 0;
    bool last = false;
    final shopOrders = <OrderData>[];
    var customOrders = <OrderData>[];

    while (!last) {
      final response = await _dio.get(
        '/orders/staff/combined',
        queryParameters: {'page': page, 'size': 50, 'sort': 'createdAt,desc'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data as Map<String, dynamic>;
      final shopPage = data['shopOrders'] as Map<String, dynamic>? ?? {};
      final content = (shopPage['content'] as List<dynamic>? ?? const [])
          .map((e) => OrderData.fromJson(e as Map<String, dynamic>))
          .toList();
      shopOrders.addAll(content);

      if (page == 0) {
        final rawCustom = data['customOrders'] as List<dynamic>? ?? const [];
        customOrders = rawCustom
            .map((e) => OrderData.fromCustomJson(e as Map<String, dynamic>))
            .toList();
      }

      last = shopPage['last'] == true;
      page += 1;

      if (content.isEmpty) {
        break;
      }
    }

    return StaffCombinedOrders(
      shopOrders: shopOrders,
      customOrders: customOrders,
    );
  }

  Future<List<OrderData>> getAllOrders() async {
    final combined = await getStaffCombinedOrders();
    return combined.shopOrders;
  }

  Future<List<OrderData>> getAllCustomOrders() async {
    final combined = await getStaffCombinedOrders();
    return combined.customOrders;
  }

  Future<CourierCombinedOrders> getCourierCombinedOrders(int courierUserId) async {
    final token = await _authRepository.getAccessToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.get(
      '/orders/for-courier/$courierUserId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data as Map<String, dynamic>;
    final shopOrders = (data['shopOrders'] as List<dynamic>? ?? const [])
        .map((e) => OrderData.fromJson(e as Map<String, dynamic>))
        .toList();
    final customOrders = (data['customOrders'] as List<dynamic>? ?? const [])
        .map((e) => OrderData.fromCustomJson(e as Map<String, dynamic>))
        .toList();

    return CourierCombinedOrders(
      shopOrders: shopOrders,
      customOrders: customOrders,
    );
  }

  Future<OrderData> getOrderById(int id, {String? token}) async {
    final authToken = token ?? await _authRepository.getAccessToken();
    if (authToken == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.get(
      '/orders/$id',
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return OrderData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderData> getCustomOrderById(int id, {String? token}) async {
    final authToken = token ?? await _authRepository.getAccessToken();
    if (authToken == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.get(
      '/custom-orders/$id',
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return OrderData.fromCustomJson(response.data as Map<String, dynamic>);
  }

  Future<List<OrderData>> getMyDeliveryOrders({
    bool onlyInDelivery = true,
  }) async {
    final profile = await _authRepository.getCurrentUserProfile();
    if (profile == null || profile.id <= 0) {
      throw Exception('Brak profilu kuriera');
    }

    final combined = await getCourierCombinedOrders(profile.id);
    final orders = combined.all;
    if (!onlyInDelivery) {
      return orders;
    }
    return orders.where((order) => order.status == 'IN_DELIVERY').toList();
  }

  Future<OrderData> patchStatus({
    required int id,
    required String status,
  }) async {
    final token = await _authRepository.getAccessToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.patch(
      '/orders/$id/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return OrderData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderData> patchCustomStatus({
    required int id,
    required String status,
  }) async {
    final token = await _authRepository.getAccessToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.patch(
      '/custom-orders/$id/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return OrderData.fromCustomJson(response.data as Map<String, dynamic>);
  }
}

