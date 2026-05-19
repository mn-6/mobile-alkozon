import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_service.dart';

class InventoryItem {
  const InventoryItem({
    this.productId,
    this.rawMaterialId,
    required this.name,
    required this.quantity,
    required this.type,
    this.warehouseZone,
    this.unit,
  });

  final int? productId;
  final int? rawMaterialId;
  final String name;
  final num quantity;
  final InventoryItemType type;
  final String? warehouseZone;
  final String? unit;

  bool get isProduct => type == InventoryItemType.product;

  int? get id => isProduct ? productId : rawMaterialId;

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

  List<MapEntry<String, String>> get detailEntries {
    final rows = <MapEntry<String, String>>[];
    rows.add(MapEntry('Typ', isProduct ? 'Produkt' : 'Surowiec'));
    if (isProduct) {
      rows.add(MapEntry('Product ID', '${productId ?? '-'}'));
      rows.add(MapEntry('Nazwa', name));
      rows.add(MapEntry('Ilość', quantityLabel));
      rows.add(
        MapEntry(
          'Strefa magazynowa',
          warehouseZone?.isNotEmpty == true ? warehouseZone! : '-',
        ),
      );
    } else {
      rows.add(MapEntry('Raw Material ID', '${rawMaterialId ?? '-'}'));
      rows.add(MapEntry('Nazwa', name));
      rows.add(MapEntry('Ilość', quantityLabel));
      rows.add(MapEntry('Jednostka', unit?.isNotEmpty == true ? unit! : '-'));
    }
    return rows;
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

  static const String _apiUrl = ApiConfig.baseUrl;

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

  Future<InventoryItem> addQuantity(InventoryItem item, int amount) {
    return _changeQuantity(item, amount.abs());
  }

  Future<InventoryItem> consumeQuantity(InventoryItem item, int amount) {
    return _changeQuantity(item, -amount.abs());
  }

  Future<InventoryItem> _changeQuantity(InventoryItem item, int delta) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final isProduct = item.isProduct;
    final id = item.id;
    if (id == null) {
      throw Exception('Brak identyfikatora pozycji magazynowej');
    }

    final response = await _dio.patch(
      isProduct ? '/inventory/products/$id' : '/inventory/raw-materials/$id',
      data: {'delta': delta},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data as Map<String, dynamic>;
    return isProduct
        ? InventoryItem(
            productId: _toInt(data['productId']),
            name: data['name'] as String? ?? item.name,
            quantity: data['quantity'] as num? ?? item.quantity,
            type: InventoryItemType.product,
            warehouseZone:
                data['warehouseZone'] as String? ?? item.warehouseZone,
          )
        : InventoryItem(
            rawMaterialId: _toInt(data['id']),
            name: data['name'] as String? ?? item.name,
            quantity: data['quantity'] as num? ?? item.quantity,
            type: InventoryItemType.rawMaterial,
            unit: data['unit'] as String? ?? item.unit,
          );
  }

  InventoryItem _mapProduct(Map<String, dynamic> json) {
    return InventoryItem(
      productId: _toInt(json['productId']),
      name: json['name'] as String? ?? 'Produkt',
      quantity: json['quantity'] as int? ?? 0,
      type: InventoryItemType.product,
      warehouseZone: json['warehouseZone'] as String?,
    );
  }

  InventoryItem _mapRawMaterial(Map<String, dynamic> json) {
    final quantity = json['quantity'];
    return InventoryItem(
      rawMaterialId: _toInt(json['id']),
      name: json['name'] as String? ?? 'Surowiec',
      quantity: quantity is num ? quantity : num.parse(quantity.toString()),
      type: InventoryItemType.rawMaterial,
      unit: json['unit'] as String?,
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
