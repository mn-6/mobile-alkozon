import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<InventoryOverview> getInventory();
  Future<InventoryItem> addQuantity(InventoryItem item, int amount);
  Future<InventoryItem> consumeQuantity(InventoryItem item, int amount);
  Future<void> consumeProductById({
    required int productId,
    required int quantity,
  });
}
