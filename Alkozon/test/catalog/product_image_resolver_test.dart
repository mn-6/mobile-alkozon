import 'package:alkozon/features/catalog/domain/product_image_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductImageResolver', () {
    test('findAssetForName returns direct map match', () {
      expect(
        ProductImageResolver.findAssetForName('Absolut Vodka'),
        'lib/imgs/products/vodka/Absolut Vodka.png',
      );
    });

    test('findAssetForName matches after normalization', () {
      expect(
        ProductImageResolver.findAssetForName('  absolut   vodka  '),
        'lib/imgs/products/vodka/Absolut Vodka.png',
      );
    });

    test('findAssetForName returns null for empty or unknown names', () {
      expect(ProductImageResolver.findAssetForName(null), isNull);
      expect(ProductImageResolver.findAssetForName(''), isNull);
      expect(ProductImageResolver.findAssetForName('Nieistniejący produkt'), isNull);
    });

    test('findAssetForNames returns first matching asset', () {
      expect(
        ProductImageResolver.findAssetForNames([
          'nieznany',
          'Absolut Vodka',
        ]),
        'lib/imgs/products/vodka/Absolut Vodka.png',
      );
    });
  });
}
