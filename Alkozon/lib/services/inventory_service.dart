import 'package:dio/dio.dart';

import 'auth_service.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.type,
    this.warehouseZone,
    this.unit,
  });

  final int id;
  final String name;
  final num quantity;
  final InventoryItemType type;
  final String? warehouseZone;
  final String? unit;

  bool get isProduct => type == InventoryItemType.product;

  String get quantityLabel {
    if (quantity is int) {
      return quantity.toString();
    }
    final doubleValue = quantity.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.toInt().toString();
    }
    return doubleValue.toStringAsFixed(2);
  }

  String get subtitle {
    if (isProduct) {
      return warehouseZone?.isNotEmpty == true
          ? 'Strefa magazynowa: $warehouseZone'
          : 'Produkt gotowy';
    }
    return unit?.isNotEmpty == true ? 'Jednostka: $unit' : 'Surowiec';
  }

  String get detailLabel {
    if (isProduct) {
      return warehouseZone?.isNotEmpty == true
          ? 'Strefa magazynowa'
          : 'Typ pozycji';
    }
    return unit?.isNotEmpty == true ? 'Jednostka' : 'Typ pozycji';
  }

  String get detailValue {
    if (isProduct) {
      return warehouseZone?.isNotEmpty == true
          ? warehouseZone!
          : 'Produkt gotowy';
    }
    return unit?.isNotEmpty == true ? unit! : 'Surowiec';
  }
}

enum InventoryItemType { product, rawMaterial }

class InventoryOverview {
  const InventoryOverview({required this.products, required this.rawMaterials});

  final List<InventoryItem> products;
  final List<InventoryItem> rawMaterials;

  List<InventoryItem> get allItems => [...products, ...rawMaterials];
}

class InventoryService {
  InventoryService({AuthService? authService})
    : _authService = authService ?? AuthService();

  static const String _apiUrl = 'http://192.168.0.101:8080/api';

  final AuthService _authService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<InventoryOverview> getInventory() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.get(
      '/inventory',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data as Map<String, dynamic>;
    final products = (data['products'] as List<dynamic>? ?? [])
        .map((item) => _mapProduct(item as Map<String, dynamic>))
        .toList();
    final rawMaterials = (data['rawMaterials'] as List<dynamic>? ?? [])
        .map((item) => _mapRawMaterial(item as Map<String, dynamic>))
        .toList();

    return InventoryOverview(products: products, rawMaterials: rawMaterials);
  }

  InventoryItem _mapProduct(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['productId'] as int,
      name: json['name'] as String? ?? 'Produkt',
      quantity: json['quantity'] as int? ?? 0,
      type: InventoryItemType.product,
      warehouseZone: json['warehouseZone'] as String?,
    );
  }

  InventoryItem _mapRawMaterial(Map<String, dynamic> json) {
    final quantity = json['quantity'];
    return InventoryItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Surowiec',
      quantity: quantity is num ? quantity : num.parse(quantity.toString()),
      type: InventoryItemType.rawMaterial,
      unit: json['unit'] as String?,
    );
  }
}
