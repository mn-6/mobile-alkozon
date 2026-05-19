import '../data/product_image_map.dart';

class ProductImageResolver {
  ProductImageResolver._();

  static Future<void> ensureInitialized() async {}

  static String? findAssetForName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();
    final direct = productImageByBackendName[trimmed];
    if (direct != null) {
      return direct;
    }

    final normalized = _normalize(trimmed);
    for (final entry in productImageByBackendName.entries) {
      if (_normalize(entry.key) == normalized) {
        return entry.value;
      }
    }

    return null;
  }

  static String? findAssetForNames(Iterable<String> values) {
    for (final value in values) {
      final match = findAssetForName(value);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  static String _normalize(String input) {
    var normalized = input.toLowerCase().trim();

    const replacements = {
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ź': 'z',
      'ż': 'z',
      'é': 'e',
      'ö': 'o',
      'ü': 'u',
      '_': ' ',
      '&': ' ',
      '.': ' ',
      ',': ' ',
      '-': ' ',
      '/': ' ',
      '\\': ' ',
      "'": ' ',
      '"': ' ',
      ':': ' ',
    };

    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }
}
