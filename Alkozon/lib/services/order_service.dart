import 'package:dio/dio.dart';

import 'auth_service.dart';

class DeliveryAssignment {
  const DeliveryAssignment({required this.id, required this.orderId});

  final int id;
  final int orderId;

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    return DeliveryAssignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
    );
  }
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

  String get displayNumber => orderNumber ?? clientOrderNumber ?? '#$id';
}

class OrderService {
  OrderService({AuthService? authService})
    : _authService = authService ?? AuthService();

  static const String _apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  final AuthService _authService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<List<OrderData>> getAllOrders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    int page = 0;
    bool last = false;
    final all = <OrderData>[];

    while (!last) {
      final response = await _dio.get(
        '/orders',
        queryParameters: {'page': page, 'size': 50, 'sort': 'createdAt,desc'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data as Map<String, dynamic>;
      final content = (data['content'] as List<dynamic>? ?? const [])
          .map((e) => OrderData.fromJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(content);

      last = data['last'] == true;
      page += 1;

      if (content.isEmpty) {
        break;
      }
    }

    return all;
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

  Future<List<OrderData>> getMyDeliveryOrders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.get(
      '/deliveries/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final rawList = response.data as List<dynamic>? ?? const [];
    final assignments = rawList
        .map((e) => DeliveryAssignment.fromJson(e as Map<String, dynamic>))
        .toList();

    final orders = <OrderData>[];
    for (final assignment in assignments) {
      if (assignment.orderId <= 0) continue;
      try {
        final order = await getOrderById(assignment.orderId, token: token);
        if (order.status == 'IN_DELIVERY') {
          orders.add(order);
        }
      } catch (_) {
        // Pomijamy pojedyncze błędy szczegółów zamówienia, aby nie blokować listy.
      }
    }

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
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
}
