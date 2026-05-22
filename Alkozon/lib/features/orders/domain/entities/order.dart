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

  bool get hasStructuredData {
    bool has(String? value) => value != null && value.trim().isNotEmpty;
    return has(streetAddress) ||
        has(city) ||
        has(postalCode) ||
        has(recipientName);
  }

  String? get formattedSingleLine {
    if (!hasStructuredData) {
      return null;
    }
    final parts = <String>[
      if ((streetAddress ?? '').trim().isNotEmpty) streetAddress!.trim(),
      if ((postalCode ?? '').trim().isNotEmpty) postalCode!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
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
    final preferences = prefsRaw is Map
        ? Map<String, dynamic>.from(prefsRaw)
        : <String, dynamic>{};
    final deliveryDetails = _deliveryDetailsFromCustomPreferences(preferences);
    final deliveryAddress = deliveryDetails?.formattedSingleLine;

    return OrderData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: null,
      clientOrderNumber: json['clientOrderNumber'] as String?,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: status,
      deliveryAddress: deliveryAddress,
      deliveryDetails: deliveryDetails,
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
      preferences: preferences,
      assignedToId: (json['assignedToId'] as num?)?.toInt(),
    );
  }

  static DeliveryDetails? _deliveryDetailsFromCustomPreferences(
    Map<String, dynamic> preferences,
  ) {
    final nested = preferences['delivery'];
    if (nested is Map) {
      final fromNested = DeliveryDetails.fromJson(
        Map<String, dynamic>.from(nested),
      );
      if (fromNested.hasStructuredData) {
        return fromNested;
      }
    }

    final fromFlat = DeliveryDetails.fromJson(preferences);
    if (fromFlat.hasStructuredData) {
      return fromFlat;
    }

    return null;
  }

  String get displayNumber => orderNumber ?? clientOrderNumber ?? '#$id';
}


