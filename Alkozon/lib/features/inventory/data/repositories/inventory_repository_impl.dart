import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._remoteDataSource);

  final InventoryRemoteDataSource _remoteDataSource;

  @override
  Future<InventoryOverview> getInventory() => _remoteDataSource.getInventory();

  @override
  Future<InventoryItem> addQuantity(InventoryItem item, int amount) =>
      _remoteDataSource.addQuantity(item, amount);

  @override
  Future<InventoryItem> consumeQuantity(InventoryItem item, int amount) =>
      _remoteDataSource.consumeQuantity(item, amount);

  @override
  Future<void> consumeProductById({
    required int productId,
    required int quantity,
  }) => _remoteDataSource.consumeProductById(
    productId: productId,
    quantity: quantity,
  );
}
