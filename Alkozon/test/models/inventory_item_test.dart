import 'package:alkozon/features/inventory/domain/entities/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryItem', () {
    test('quantityLabel formats integers and decimals', () {
      const intItem = InventoryItem(
        productId: 1,
        name: 'Piwo',
        quantity: 12,
        type: InventoryItemType.product,
      );
      const decimalItem = InventoryItem(
        rawMaterialId: 2,
        name: 'Słód',
        quantity: 1.5,
        type: InventoryItemType.rawMaterial,
        unit: 'kg',
      );

      expect(intItem.quantityLabel, '12');
      expect(decimalItem.quantityLabel, '1.50');
    });

    test('subtitle and detailEntries differ for product vs raw material', () {
      const product = InventoryItem(
        productId: 5,
        name: 'Heineken',
        quantity: 3,
        type: InventoryItemType.product,
        warehouseZone: 'A-1',
      );
      const raw = InventoryItem(
        rawMaterialId: 9,
        name: 'Chmiel',
        quantity: 2,
        type: InventoryItemType.rawMaterial,
        unit: 'kg',
      );

      expect(product.isProduct, isTrue);
      expect(product.id, 5);
      expect(product.subtitle, 'Strefa magazynowa: A-1');
      expect(product.detailValue, 'A-1');
      expect(
        product.detailEntries.map((e) => e.key),
        containsAll(['Typ', 'Product ID', 'Strefa magazynowa']),
      );

      expect(raw.isProduct, isFalse);
      expect(raw.id, 9);
      expect(raw.subtitle, 'Jednostka: kg');
      expect(raw.detailValue, 'kg');
    });
  });

  group('InventoryOverview', () {
    test('allItems merges products and raw materials', () {
      const overview = InventoryOverview(
        products: [
          InventoryItem(
            productId: 1,
            name: 'A',
            quantity: 1,
            type: InventoryItemType.product,
          ),
        ],
        rawMaterials: [
          InventoryItem(
            rawMaterialId: 2,
            name: 'B',
            quantity: 2,
            type: InventoryItemType.rawMaterial,
          ),
        ],
      );

      expect(overview.allItems, hasLength(2));
    });
  });
}
