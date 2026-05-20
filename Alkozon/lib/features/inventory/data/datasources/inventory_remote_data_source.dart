import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._authRepository, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final AuthRepository _authRepository;
  final Dio _dio;

  Future<InventoryOverview> getInventory() async {
    final token = await _authRepository.getAccessToken();
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

  Future<void> consumeProductById({
    required int productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;

    final overview = await getInventory();
    InventoryItem? product;
    for (final item in overview.products) {
      if (item.productId == productId) {
        product = item;
        break;
      }
    }
    if (product == null) {
      throw Exception('Brak pozycji magazynowej dla produktu ID $productId');
    }
    await consumeQuantity(product, quantity);
  }

  Future<InventoryItem> _changeQuantity(InventoryItem item, int delta) async {
    final token = await _authRepository.getAccessToken();
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
