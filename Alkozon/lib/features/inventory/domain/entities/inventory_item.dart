enum InventoryItemType { product, rawMaterial }

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

class InventoryOverview {
  const InventoryOverview({required this.products, required this.rawMaterials});

  final List<InventoryItem> products;
  final List<InventoryItem> rawMaterials;

  List<InventoryItem> get allItems => [...products, ...rawMaterials];
}
