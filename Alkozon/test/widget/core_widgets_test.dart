import 'package:alkozon/core/widgets/horizontal_scroll_text.dart';
import 'package:alkozon/core/widgets/product_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HorizontalScrollText', () {
    testWidgets('renders text in horizontal scroll view', (tester) async {
      const label = 'Bardzo długa nazwa produktu premium edition';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HorizontalScrollText(text: label),
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('ProductThumbnail', () {
    testWidgets('shows fallback icon for unknown product', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductThumbnail(
              productNames: ['Nieistniejący produkt testowy'],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });

    testWidgets('shows asset image for known catalog name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductThumbnail(
              productNames: ['Absolut Vodka'],
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
