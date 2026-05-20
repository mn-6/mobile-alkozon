import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_service.dart';

class StaffCombinedOrders {
  const StaffCombinedOrders({
    required this.shopOrders,
    required this.customOrders,
  });

  final List<OrderData> shopOrders;
  final List<OrderData> customOrders;
}

class CourierCombinedOrders {
  const CourierCombinedOrders({
    required this.shopOrders,
    required this.customOrders,
  });

  final List<OrderData> shopOrders;
  final List<OrderData> customOrders;

  List<OrderData> get all =>
      [...shopOrders, ...customOrders]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? '-',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeliveryDetails {
  const DeliveryDetails({
    this.recipientName,
    this.streetAddress,
    this.city,
    this.postalCode,
    this.country,
    this.deliveryNotes,
    this.paymentMethod,
  });

  final String? recipientName;
  final String? streetAddress;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? deliveryNotes;
  final String? paymentMethod;

  factory DeliveryDetails.fromJson(Map<String, dynamic> json) {
    return DeliveryDetails(
      recipientName: json['recipientName'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      deliveryNotes: json['deliveryNotes'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}

class OrderData {
  const OrderData({
    required this.id,
    required this.orderNumber,
    required this.clientOrderNumber,
    required this.customerId,
    required this.status,
    required this.deliveryAddress,
    this.deliveryDetails,
    required this.totalAmount,
    required this.createdAt,
    this.deliveredAt,
    required this.items,
    this.isCustomOrder = false,
    this.description,
    this.preferences,
    this.assignedToId,
  });

  final int id;
  final String? orderNumber;
  final String? clientOrderNumber;
  final int customerId;
  final String status;
  final String? deliveryAddress;
  final DeliveryDetails? deliveryDetails;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final bool isCustomOrder;
  final String? description;
  final Map<String, dynamic>? preferences;
  final int? assignedToId;

  factory OrderData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawDeliveryDetails = json['deliveryDetails'];

    return OrderData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: json['orderNumber'] as String?,
      clientOrderNumber: json['clientOrderNumber'] as String?,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String? ?? 'SUBMITTED').toUpperCase(),
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryDetails: rawDeliveryDetails is Map<String, dynamic>
          ? DeliveryDetails.fromJson(rawDeliveryDetails)
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String).toLocal(),
      items: rawItems
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory OrderData.fromCustomJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'] as String?;
    final updatedRaw = json['updatedAt'] as String?;
    final description = json['description'] as String?;
    final status = (json['status'] as String? ?? 'SUBMITTED').toUpperCase();
    final prefsRaw = json['preferences'];

    return OrderData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: null,
      clientOrderNumber: json['clientOrderNumber'] as String?,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: status,
      deliveryAddress: null,
      deliveryDetails: null,
      totalAmount: 0,
      createdAt:
          createdRaw != null
              ? DateTime.parse(createdRaw).toLocal()
              : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String).toLocal()
          : (status == 'DELIVERED' || status == 'CANCELLED') &&
                  updatedRaw != null
              ? DateTime.parse(updatedRaw).toLocal()
              : null,
      items: const [],
      isCustomOrder: true,
      description: description,
      preferences:
          prefsRaw is Map ? Map<String, dynamic>.from(prefsRaw) : const {},
      assignedToId: (json['assignedToId'] as num?)?.toInt(),
    );
  }

  String get displayNumber => orderNumber ?? clientOrderNumber ?? '#$id';
}

class OrderService {
  OrderService({AuthService? authService})
    : _authService = authService ?? AuthService();

  static const String _apiUrl = ApiConfig.baseUrl;

  final AuthService _authService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<StaffCombinedOrders> getStaffCombinedOrders() async {
    final token = await _authService.getToken();
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
    final token = await _authService.getToken();
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
    final authToken = token ?? await _authService.getToken();
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
    final authToken = token ?? await _authService.getToken();
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
    final profile = await _authService.getCurrentUserProfile();
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
    final token = await _authService.getToken();
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
    final token = await _authService.getToken();
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
